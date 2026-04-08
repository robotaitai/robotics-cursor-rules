#!/bin/bash
#
# Bootstrap an adaptive project knowledge tree under ./agent-knowledge/.
#
# Usage:
#   ./bootstrap-memory-tree.sh [project-dir] [profile]
#   ./bootstrap-memory-tree.sh .                 # auto-detect profile
#   ./bootstrap-memory-tree.sh /path/to/project robotics
#
# Profiles: web-app | robotics | ml-platform | hybrid
#
# What it does:
#   1. Detects the project profile from manifests, docs, configs, tests, and workflows
#   2. Creates the v2 knowledge tree with Memory/, Evidence/, Sessions/, Outputs/, Dashboards/
#   3. Generates durable notes with YAML frontmatter
#   4. Bootstraps profile-specific memory branches
#   5. Creates lightweight Obsidian starter files
#
# What it does NOT do:
#   - Classify history into curated memory automatically
#   - Replace the agent's judgment during backfill or writeback
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_RULES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/lib/knowledge-common.sh"
TEMPLATES_DIR="$AGENTS_RULES_DIR/templates/memory"
PROJECT_TEMPLATE_DIR="$AGENTS_RULES_DIR/templates/project/agent-knowledge"
DASHBOARD_TEMPLATES_DIR="$AGENTS_RULES_DIR/templates/dashboards"
STATUS_TEMPLATE="$AGENTS_RULES_DIR/templates/project/agent-knowledge/STATUS.md"

TARGET_PROJECT_ARG="."
PROFILE=""
POSITIONAL=()
CHANGES=()

while [ "$#" -gt 0 ]; do
    if kc_parse_common_flag "$@" ; then
        shift
        continue
    fi
    flag_status=$?
    if [ "$flag_status" -eq 2 ]; then
        shift 2
        continue
    fi

    case "$1" in
        --project)
            TARGET_PROJECT_ARG="${2:-.}"
            shift 2
            ;;
        --profile)
            PROFILE="${2:-}"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [ "$SHOW_HELP" -eq 1 ]; then
    cat <<'EOF'
Usage:
  scripts/bootstrap-memory-tree.sh [project-dir] [profile]
  scripts/bootstrap-memory-tree.sh --project <dir> [--profile <profile>] [--dry-run] [--json] [--summary-file <file>] [--force]
EOF
    exit 0
fi

if [ ${#POSITIONAL[@]} -ge 1 ]; then
    TARGET_PROJECT_ARG="${POSITIONAL[0]}"
fi
if [ ${#POSITIONAL[@]} -ge 2 ] && [ -z "$PROFILE" ]; then
    PROFILE="${POSITIONAL[1]}"
fi

kc_load_project_context "$TARGET_PROJECT_ARG"
DATE="$(kc_today)"

[ -L "$KNOWLEDGE_POINTER_PATH" ] || kc_fail "Bootstrap requires ./agent-knowledge to already be a pointer to the external knowledge folder. Run: agent-knowledge init"

MANIFEST_PATHS=""
DOC_PATHS=""
CONFIG_PATHS=""
TEST_PATHS=""
WORKFLOW_PATHS=""
TOP_LEVEL_DIRS=""

relative_path() {
    sed "s|$TARGET_PROJECT/||" | sed "s|^$TARGET_PROJECT$|.|"
}

list_existing_paths() {
    local base="$1"
    shift
    local path=""

    for path in "$@"; do
        if [ -e "$base/$path" ]; then
            printf "%s\n" "$path"
        fi
    done
}

list_top_level_dirs() {
    find "$TARGET_PROJECT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
        | relative_path \
        | grep -Ev '^(agent-knowledge|node_modules|vendor|\.git|\.cursor|dist|build|\.next|__pycache__)$' \
        | head -10 || true
}

list_workflow_files() {
    if [ -d "$TARGET_PROJECT/.github/workflows" ]; then
        find "$TARGET_PROJECT/.github/workflows" -mindepth 1 -maxdepth 1 -type f 2>/dev/null \
            | relative_path \
            | sort
    fi
}

format_code_list() {
    awk 'NF { items[++count] = $0 }
         END {
             for (i = 1; i <= count; i++) {
                 printf "`%s`", items[i]
                 if (i < count) {
                     printf ", "
                 }
             }
         }'
}

format_branch_links() {
    local areas="$1"
    local area=""
    local display=""
    local hint=""

    for area in $areas; do
        display="$(capitalize_first "$area")"
        hint="$(get_area_hint "$PROFILE_FILE" "$area")"
        printf -- "- [%s](%s.md)" "$display" "$area"
        if [ -n "$hint" ]; then
            printf -- " - %s" "$hint"
        fi
        printf "\n"
    done
    printf -- "- [Decisions Index](decisions/INDEX.md) - Architecture and process decisions.\n"
}

capitalize_first() {
    echo "$1" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' FS=- OFS=' '
}

manifest_count() {
    printf "%s\n" "$MANIFEST_PATHS" | awk 'NF{count++} END{print count+0}'
}

detect_profile() {
    local dir="$1"
    local docs_text=""
    local has_workspace="no"
    local manifest_total=0

    MANIFEST_PATHS="$(list_existing_paths "$dir" \
        package.json pnpm-workspace.yaml nx.json turbo.json yarn.lock pnpm-lock.yaml package-lock.json \
        pyproject.toml requirements.txt setup.py setup.cfg Pipfile poetry.lock \
        Cargo.toml Cargo.lock go.mod go.sum CMakeLists.txt Makefile package.xml)"
    DOC_PATHS="$(list_existing_paths "$dir" README.md README.rst AGENTS.md CLAUDE.md docs docs/README.md mkdocs.yml)"
    CONFIG_PATHS="$(list_existing_paths "$dir" \
        .editorconfig eslint.config.js eslint.config.mjs eslint.config.cjs .eslintrc .eslintrc.js .eslintrc.cjs \
        .prettierrc .prettierrc.json .prettierrc.yaml tsconfig.json tsconfig.base.json \
        pytest.ini mypy.ini ruff.toml .clang-format .clang-tidy .pre-commit-config.yaml)"
    TEST_PATHS="$(list_existing_paths "$dir" tests test __tests__ spec specs integration-tests launch simulation notebooks models data)"
    WORKFLOW_PATHS="$(list_workflow_files)"

    manifest_total="$(manifest_count)"

    if [ -f "$dir/pnpm-workspace.yaml" ] || [ -f "$dir/nx.json" ] || [ -f "$dir/turbo.json" ] || \
       [ -d "$dir/packages" ] || [ -d "$dir/services" ] || [ -d "$dir/apps" ] || \
       ( [ -f "$dir/package.json" ] && grep -q '"workspaces"' "$dir/package.json" 2>/dev/null ); then
        has_workspace="yes"
    fi

    docs_text="$(cat "$dir/README.md" "$dir/docs/README.md" "$dir/AGENTS.md" "$dir/CLAUDE.md" 2>/dev/null || true)"

    if [ -f "$dir/package.xml" ] || [ -f "$dir/CMakeLists.txt" ] || [ -d "$dir/urdf" ] || [ -d "$dir/launch" ] || \
       printf "%s" "$docs_text" | grep -Eiq 'ros2|ros |gazebo|rviz|urdf|moveit'; then
        echo "robotics"
        return
    fi

    if { [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; } && \
       { [ -d "$dir/notebooks" ] || [ -d "$dir/models" ] || [ -d "$dir/data" ] || \
         grep -Eiq 'torch|tensorflow|jax|sklearn|transformers|mlflow|wandb|ray' "$dir/requirements.txt" "$dir/pyproject.toml" 2>/dev/null || \
         printf "%s" "$docs_text" | grep -Eiq 'training|inference|model registry|feature store'; }; then
        echo "ml-platform"
        return
    fi

    if [ "$has_workspace" = "yes" ] || [ "$manifest_total" -ge 3 ]; then
        echo "hybrid"
        return
    fi

    if [ -f "$dir/package.json" ] && \
       grep -qE '"react"|"next"|"vue"|"svelte"|"angular"|"nuxt"|"vite"' "$dir/package.json" 2>/dev/null; then
        echo "web-app"
        return
    fi

    echo "hybrid"
}

parse_areas() {
    local profile_file="$1"
    grep "^areas:" "$profile_file" \
        | sed 's/^areas: *\[//;s/\].*//' \
        | tr ',' '\n' \
        | tr -d ' \t'
}

get_area_hint() {
    local profile_file="$1"
    local area="$2"

    grep "^  $area:" "$profile_file" 2>/dev/null \
        | sed 's/^  [^:]*: *//' \
        | sed 's/^"//;s/"$//'
}

render_text_template() {
    local src="$1"
    local dst="$2"
    local purpose_lines="${3:-}"
    local current_state_lines="${4:-}"
    local recent_change_lines="${5:-}"
    local decision_lines="${6:-}"
    local open_question_lines="${7:-}"
    local subtopic_lines="${8:-}"
    local area_name="${9:-}"
    local area_slug="${10:-}"
    local decision_slug="${11:-}"
    local short_title="${12:-}"
    local what_lines="${13:-}"
    local why_lines="${14:-}"
    local alternatives_lines="${15:-}"
    local consequences_lines="${16:-}"
    local superseded_lines="${17:-}"
    local tmp_file

    tmp_file="$(mktemp)"

    TEMPLATE_PROJECT_NAME="$PROJECT_NAME" \
    TEMPLATE_PROFILE="$PROFILE" \
    TEMPLATE_DATE="$DATE" \
    TEMPLATE_PURPOSE_LINES="$purpose_lines" \
    TEMPLATE_CURRENT_STATE_LINES="$current_state_lines" \
    TEMPLATE_RECENT_CHANGE_LINES="$recent_change_lines" \
    TEMPLATE_DECISION_LINES="$decision_lines" \
    TEMPLATE_OPEN_QUESTION_LINES="$open_question_lines" \
    TEMPLATE_SUBTOPIC_LINES="$subtopic_lines" \
    TEMPLATE_AREA_NAME="$area_name" \
    TEMPLATE_AREA_SLUG="$area_slug" \
    TEMPLATE_DECISION_SLUG="$decision_slug" \
    TEMPLATE_SHORT_TITLE="$short_title" \
    TEMPLATE_WHAT_LINES="$what_lines" \
    TEMPLATE_WHY_LINES="$why_lines" \
    TEMPLATE_ALTERNATIVES_LINES="$alternatives_lines" \
    TEMPLATE_CONSEQUENCES_LINES="$consequences_lines" \
    TEMPLATE_SUPERSEDED_LINES="$superseded_lines" \
    awk '
        BEGIN {
            project = ENVIRON["TEMPLATE_PROJECT_NAME"]
            profile = ENVIRON["TEMPLATE_PROFILE"]
            date = ENVIRON["TEMPLATE_DATE"]
            purpose_lines = ENVIRON["TEMPLATE_PURPOSE_LINES"]
            current_state_lines = ENVIRON["TEMPLATE_CURRENT_STATE_LINES"]
            recent_change_lines = ENVIRON["TEMPLATE_RECENT_CHANGE_LINES"]
            decision_lines = ENVIRON["TEMPLATE_DECISION_LINES"]
            open_question_lines = ENVIRON["TEMPLATE_OPEN_QUESTION_LINES"]
            subtopic_lines = ENVIRON["TEMPLATE_SUBTOPIC_LINES"]
            area_name = ENVIRON["TEMPLATE_AREA_NAME"]
            area_slug = ENVIRON["TEMPLATE_AREA_SLUG"]
            decision_slug = ENVIRON["TEMPLATE_DECISION_SLUG"]
            short_title = ENVIRON["TEMPLATE_SHORT_TITLE"]
            what_lines = ENVIRON["TEMPLATE_WHAT_LINES"]
            why_lines = ENVIRON["TEMPLATE_WHY_LINES"]
            alternatives_lines = ENVIRON["TEMPLATE_ALTERNATIVES_LINES"]
            consequences_lines = ENVIRON["TEMPLATE_CONSEQUENCES_LINES"]
            superseded_lines = ENVIRON["TEMPLATE_SUPERSEDED_LINES"]
        }
        {
            gsub(/<project-name>/, project)
            gsub(/<profile-type>/, profile)
            gsub(/<date>/, date)
            gsub(/<Area Name>/, area_name)
            gsub(/<area-slug>/, area_slug)
            gsub(/<decision-slug>/, decision_slug)
            gsub(/<short-title>/, short_title)

            if ($0 == "<purpose-lines>") { print purpose_lines; next }
            if ($0 == "<current-state-lines>") { print current_state_lines; next }
            if ($0 == "<recent-change-lines>") { print recent_change_lines; next }
            if ($0 == "<decision-lines>") { print decision_lines; next }
            if ($0 == "<open-question-lines>") { print open_question_lines; next }
            if ($0 == "<subtopic-lines>") { print subtopic_lines; next }
            if ($0 == "<what-lines>") { print what_lines; next }
            if ($0 == "<why-lines>") { print why_lines; next }
            if ($0 == "<alternatives-lines>") { print alternatives_lines; next }
            if ($0 == "<consequences-lines>") { print consequences_lines; next }
            if ($0 == "<superseded-lines>") { print superseded_lines; next }

            print
        }' "$src" > "$tmp_file"

    kc_apply_temp_file "$tmp_file" "$dst" "$dst"
}

copy_static_template() {
    local src="$1"
    local dst="$2"
    local label="$3"

    render_text_template "$src" "$dst"
    case "$KC_LAST_ACTION" in
        created|updated|would-create|would-update)
            CHANGES+=("$label")
            ;;
    esac
}

generic_backfill_line() {
    printf -- "- Backfill from [../Evidence/raw/README.md](../Evidence/raw/README.md) and [../Evidence/imports/README.md](../Evidence/imports/README.md) before treating this branch as complete.\n"
}

root_current_state_lines() {
    local profile_areas=""

    profile_areas="$(printf "%s\n" "$AREAS" | format_code_list)"

    printf -- '- Adaptive profile detected at bootstrap: `%s`.\n' "$PROFILE"
    printf -- "- Initial durable branches: %s.\n" "$profile_areas"
    printf -- "- Evidence is separated from curated memory under [../Evidence/raw/README.md](../Evidence/raw/README.md) and [../Evidence/imports/README.md](../Evidence/imports/README.md).\n"
    printf -- "- Session state remains separate under [../Sessions/README.md](../Sessions/README.md).\n"
}

root_recent_change_lines() {
    printf -- "- %s - Bootstrapped durable memory root and profile branches.\n" "$DATE"
}

root_decision_lines() {
    printf -- "- [decisions/INDEX.md](decisions/INDEX.md) - Decision log for architectural and process choices.\n"
}

root_open_question_lines() {
    printf -- "- Which branches need history backfill first?\n"
    printf -- "- Which decisions should be recorded explicitly from existing docs and code?\n"
}

stack_current_state() {
    printf -- '- Detected project profile: `%s`.\n' "$PROFILE"
    if [ -n "$MANIFEST_PATHS" ]; then
        printf -- "- Key manifests at bootstrap: %s.\n" "$(printf "%s\n" "$MANIFEST_PATHS" | format_code_list)"
    else
        printf -- "- No standard manifests were detected during bootstrap.\n"
    fi
    if [ -n "$CONFIG_PATHS" ]; then
        printf -- "- Config files present: %s.\n" "$(printf "%s\n" "$CONFIG_PATHS" | format_code_list)"
    fi
    generic_backfill_line
}

architecture_current_state() {
    if [ -n "$TOP_LEVEL_DIRS" ]; then
        printf -- "- Top-level directories at bootstrap: %s.\n" "$(printf "%s\n" "$TOP_LEVEL_DIRS" | format_code_list)"
    else
        printf -- "- Top-level architecture could not be summarized from directory names alone.\n"
    fi
    if [ -n "$WORKFLOW_PATHS" ]; then
        printf -- "- Workflow files detected: %s.\n" "$(printf "%s\n" "$WORKFLOW_PATHS" | format_code_list)"
    fi
    if [ -n "$TEST_PATHS" ]; then
        printf -- "- Test or validation paths detected: %s.\n" "$(printf "%s\n" "$TEST_PATHS" | format_code_list)"
    fi
    generic_backfill_line
}

conventions_current_state() {
    if [ -n "$CONFIG_PATHS" ]; then
        printf -- "- Convention signals available from config files: %s.\n" "$(printf "%s\n" "$CONFIG_PATHS" | format_code_list)"
    else
        printf -- "- No obvious convention files were detected during bootstrap.\n"
    fi
    printf -- "- Durable conventions should be written only after they are confirmed from code, docs, or repeated practice.\n"
}

gotchas_current_state() {
    printf -- "- No verified project-specific gotchas have been curated yet.\n"
    printf -- "- Treat evidence and session traces as hints until verified in code, config, docs, or workflows.\n"
}

integrations_current_state() {
    printf -- "- Integration details have not been curated yet.\n"
    if [ -n "$DOC_PATHS" ]; then
        printf -- "- Start backfill from docs and manifests: %s.\n" "$(printf "%s\n" "$DOC_PATHS" | format_code_list)"
    fi
}

hardware_current_state() {
    local hardware_paths=""
    hardware_paths="$(list_existing_paths "$TARGET_PROJECT" urdf meshes config launch)"
    if [ -n "$hardware_paths" ]; then
        printf -- "- Hardware-related paths detected: %s.\n" "$(printf "%s\n" "$hardware_paths" | format_code_list)"
    else
        printf -- "- No hardware inventory has been curated yet.\n"
    fi
    generic_backfill_line
}

simulation_current_state() {
    local sim_paths=""
    sim_paths="$(list_existing_paths "$TARGET_PROJECT" simulation sim worlds launch gazebo ign)"
    if [ -n "$sim_paths" ]; then
        printf -- "- Simulation-related paths detected: %s.\n" "$(printf "%s\n" "$sim_paths" | format_code_list)"
    else
        printf -- "- No simulation environment has been curated yet.\n"
    fi
    generic_backfill_line
}

datasets_current_state() {
    local data_paths=""
    data_paths="$(list_existing_paths "$TARGET_PROJECT" data datasets notebooks)"
    if [ -n "$data_paths" ]; then
        printf -- "- Data-related paths detected: %s.\n" "$(printf "%s\n" "$data_paths" | format_code_list)"
    else
        printf -- "- No dataset inventory has been curated yet.\n"
    fi
    generic_backfill_line
}

models_current_state() {
    local model_paths=""
    model_paths="$(list_existing_paths "$TARGET_PROJECT" models checkpoints artifacts)"
    if [ -n "$model_paths" ]; then
        printf -- "- Model-related paths detected: %s.\n" "$(printf "%s\n" "$model_paths" | format_code_list)"
    else
        printf -- "- No active model catalog has been curated yet.\n"
    fi
    generic_backfill_line
}

deployments_current_state() {
    if [ -n "$WORKFLOW_PATHS" ]; then
        printf -- "- Deployment or CI workflow signals detected: %s.\n" "$(printf "%s\n" "$WORKFLOW_PATHS" | format_code_list)"
    else
        printf -- "- No workflow files were detected during bootstrap.\n"
    fi
    generic_backfill_line
}

area_open_questions() {
    local area="$1"

    case "$area" in
        stack)
            printf -- "- Which dependencies, runtimes, or external constraints should become durable memory?\n"
            ;;
        architecture)
            printf -- "- Which directories or services define the real long-term architecture boundaries?\n"
            ;;
        conventions)
            printf -- "- Which patterns are enforced by code review or tooling rather than preference?\n"
            ;;
        gotchas)
            printf -- "- Which operational traps or non-obvious constraints are worth preserving durably?\n"
            ;;
        integrations)
            printf -- "- Which external systems are production-critical and how are they connected?\n"
            ;;
        hardware)
            printf -- "- Which sensors, actuators, or calibration constraints must future sessions know first?\n"
            ;;
        simulation)
            printf -- "- Which sim-vs-real differences matter enough to preserve durably?\n"
            ;;
        datasets)
            printf -- "- Which datasets are canonical, versioned, or risky enough to document durably?\n"
            ;;
        models)
            printf -- "- Which model versions or rollback rules are durable enough for memory?\n"
            ;;
        deployments)
            printf -- "- Which environments, rollout steps, or promotion rules need durable notes?\n"
            ;;
        *)
            printf -- "- Which verified facts in this branch should move from evidence into curated memory first?\n"
            ;;
    esac
}

area_current_state() {
    local area="$1"

    case "$area" in
        stack) stack_current_state ;;
        architecture) architecture_current_state ;;
        conventions) conventions_current_state ;;
        gotchas) gotchas_current_state ;;
        integrations) integrations_current_state ;;
        hardware) hardware_current_state ;;
        simulation) simulation_current_state ;;
        datasets) datasets_current_state ;;
        models) models_current_state ;;
        deployments) deployments_current_state ;;
        *) generic_backfill_line ;;
    esac
}

area_recent_changes() {
    local area="$1"
    printf -- '- %s - Bootstrapped `%s` branch from repo inspection.\n' "$DATE" "$area"
}

area_decision_lines() {
    printf -- "- No decisions linked yet. See [decisions/INDEX.md](decisions/INDEX.md).\n"
}

area_subtopic_lines() {
    printf -- "- None yet.\n"
}

render_dashboard_note() {
    local src="$1"
    local dst="$2"
    local label="$3"

    render_text_template "$src" "$dst"
    case "$KC_LAST_ACTION" in
        created|updated|would-create|would-update)
            CHANGES+=("$label")
            ;;
    esac
}

if [ -z "$PROFILE" ]; then
    PROFILE="$(detect_profile "$TARGET_PROJECT")"
    detect_profile "$TARGET_PROJECT" >/dev/null
    kc_log "Auto-detected profile: $PROFILE"
else
    # Preload signal summaries for later note generation.
    detect_profile "$TARGET_PROJECT" >/dev/null
fi

PROFILE_FILE="$TEMPLATES_DIR/profile.$PROFILE.yaml"
if [ ! -f "$PROFILE_FILE" ]; then
    kc_fail "Unknown profile: $PROFILE (available: web-app, robotics, ml-platform, hybrid)"
fi

if [ -f "$AGENT_PROJECT_FILE" ]; then
    tmp_file="$(mktemp)"
    sed "s/^\([[:space:]]*profile:[[:space:]]*\).*/\1$PROFILE/" "$AGENT_PROJECT_FILE" > "$tmp_file"
    kc_apply_temp_file "$tmp_file" "$AGENT_PROJECT_FILE" ".agent-project.yaml"
    case "$KC_LAST_ACTION" in
        created|updated|would-create|would-update)
            CHANGES+=(".agent-project.yaml")
            ;;
    esac
fi

AREAS="$(parse_areas "$PROFILE_FILE")"
TOP_LEVEL_DIRS="$(list_top_level_dirs)"

kc_log "Bootstrapping memory tree: $PROJECT_NAME ($PROFILE)"
kc_log ""

for dir in \
    "$KNOWLEDGE_DIR" \
    "$MEMORY_DIR" \
    "$DECISIONS_DIR" \
    "$EVIDENCE_DIR" \
    "$EVIDENCE_RAW_DIR" \
    "$EVIDENCE_IMPORTS_DIR" \
    "$SESSIONS_DIR" \
    "$OUTPUTS_DIR" \
    "$DASHBOARDS_DIR" \
    "$LOCAL_TEMPLATES_DIR" \
    "$OBSIDIAN_DIR"; do
    kc_ensure_dir "$dir" "$dir"
done

copy_static_template "$PROJECT_TEMPLATE_DIR/INDEX.md" "$KNOWLEDGE_DIR/INDEX.md" "agent-knowledge/INDEX.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Evidence/README.md" "$EVIDENCE_DIR/README.md" "agent-knowledge/Evidence/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Evidence/raw/README.md" "$EVIDENCE_RAW_DIR/README.md" "agent-knowledge/Evidence/raw/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Evidence/imports/README.md" "$EVIDENCE_IMPORTS_DIR/README.md" "agent-knowledge/Evidence/imports/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Sessions/README.md" "$SESSIONS_DIR/README.md" "agent-knowledge/Sessions/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Outputs/README.md" "$OUTPUTS_DIR/README.md" "agent-knowledge/Outputs/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Dashboards/INDEX.md" "$DASHBOARDS_DIR/INDEX.md" "agent-knowledge/Dashboards/INDEX.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Templates/README.md" "$LOCAL_TEMPLATES_DIR/README.md" "agent-knowledge/Templates/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/.obsidian/README.md" "$OBSIDIAN_DIR/README.md" "agent-knowledge/.obsidian/README.md"
copy_static_template "$PROJECT_TEMPLATE_DIR/Memory/decisions/INDEX.md" "$DECISIONS_DIR/INDEX.md" "agent-knowledge/Memory/decisions/INDEX.md"

kc_copy_file "$PROJECT_TEMPLATE_DIR/.obsidian/core-plugins.json" "$OBSIDIAN_DIR/core-plugins.json" "agent-knowledge/.obsidian/core-plugins.json"
case "$KC_LAST_ACTION" in
    created|updated|would-create|would-update)
        CHANGES+=("agent-knowledge/.obsidian/core-plugins.json")
        ;;
esac
kc_copy_file "$PROJECT_TEMPLATE_DIR/.obsidian/app.json" "$OBSIDIAN_DIR/app.json" "agent-knowledge/.obsidian/app.json"
case "$KC_LAST_ACTION" in
    created|updated|would-create|would-update)
        CHANGES+=("agent-knowledge/.obsidian/app.json")
        ;;
esac

kc_replace_in_template \
    "$STATUS_TEMPLATE" \
    "$STATUS_FILE" \
    "agent-knowledge/STATUS.md" \
    "<project-name>" "$PROJECT_NAME" \
    "<profile-type>" "$PROFILE" \
    "<absolute-path-to-dedicated-knowledge-folder>" "$KNOWLEDGE_REAL_DIR"
case "$KC_LAST_ACTION" in
    created|updated|would-create|would-update)
        CHANGES+=("agent-knowledge/STATUS.md")
        ;;
esac

render_dashboard_note \
    "$DASHBOARD_TEMPLATES_DIR/project-overview.template.md" \
    "$DASHBOARDS_DIR/project-overview.md" \
    "agent-knowledge/Dashboards/project-overview.md"
render_dashboard_note \
    "$DASHBOARD_TEMPLATES_DIR/session-rollup.template.md" \
    "$DASHBOARDS_DIR/session-rollup.md" \
    "agent-knowledge/Dashboards/session-rollup.md"

render_text_template \
    "$TEMPLATES_DIR/MEMORY.root.template.md" \
    "$MEMORY_ROOT" \
    "" \
    "$(root_current_state_lines)" \
    "$(root_recent_change_lines)" \
    "$(root_decision_lines)" \
    "$(root_open_question_lines)" \
    "$(format_branch_links "$AREAS")"
case "$KC_LAST_ACTION" in
    created|updated|would-create|would-update)
        CHANGES+=("agent-knowledge/Memory/MEMORY.md")
        ;;
esac

AREA_SRC="$TEMPLATES_DIR/area.template.md"
for area in $AREAS; do
    dst="$MEMORY_DIR/$area.md"
    render_text_template \
        "$AREA_SRC" \
        "$dst" \
        "$(get_area_hint "$PROFILE_FILE" "$area")" \
        "$(area_current_state "$area")" \
        "$(area_recent_changes "$area")" \
        "$(area_decision_lines)" \
        "$(area_open_questions "$area")" \
        "$(area_subtopic_lines)" \
        "$(capitalize_first "$area")" \
        "$area"
    case "$KC_LAST_ACTION" in
        created|updated|would-create|would-update)
            CHANGES+=("agent-knowledge/Memory/$area.md")
            ;;
    esac
done

kc_status_load
STATUS_PROFILE="$PROFILE"
STATUS_REAL_PATH="$KNOWLEDGE_REAL_DIR"
STATUS_POINTER_PATH="$POINTER_DISPLAY"
if [ "${DRY_RUN:-0}" -eq 0 ] && [ ${#CHANGES[@]} -gt 0 ]; then
    STATUS_LAST_BOOTSTRAP="$(kc_now_utc)"
fi
kc_status_write

json_summary="{"
json_summary="$json_summary\"script\":\"bootstrap-memory-tree\","
json_summary="$json_summary\"project_root\":\"$(kc_json_escape "$TARGET_PROJECT")\","
json_summary="$json_summary\"profile\":\"$(kc_json_escape "$PROFILE")\","
json_summary="$json_summary\"real_knowledge_path\":\"$(kc_json_escape "$KNOWLEDGE_REAL_DIR")\","
json_summary="$json_summary\"dry_run\":$(kc_json_bool "$DRY_RUN"),"
json_summary="$json_summary\"changes\":$(kc_json_array "${CHANGES[@]+"${CHANGES[@]}"}")"
json_summary="$json_summary}"
kc_write_json_output "$json_summary"

if [ "$JSON_MODE" -ne 1 ]; then
    kc_log ""
    kc_log "Memory tree ready for: $PROJECT_NAME"
    kc_log "Next steps:"
    kc_log "  1. agent-knowledge import --project $TARGET_PROJECT"
    kc_log "  2. agent-knowledge validate --project $TARGET_PROJECT"
    kc_log "  3. Backfill memory: agent-driven from Evidence/ into Memory/"
fi
