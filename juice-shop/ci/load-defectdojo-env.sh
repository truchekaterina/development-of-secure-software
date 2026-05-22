# shellcheck shell=sh
# Source from CI jobs: . ./ci/load-defectdojo-env.sh && load_defectdojo_env
load_defectdojo_env() {
  if [ ! -f defectdojo.env ]; then
    echo "ERROR: defectdojo.env not found (run defectdojo-init first)"
    return 1
  fi
  DEFECTDOJO_ENGAGEMENTID=$(grep -E '^DEFECTDOJO_ENGAGEMENTID=' defectdojo.env | head -1 | cut -d= -f2- | tr -d '\r"')
  DEFECTDOJO_ENGAGEMENT_NAME=$(grep -E '^DEFECTDOJO_ENGAGEMENT_NAME=' defectdojo.env | head -1 | sed 's/^DEFECTDOJO_ENGAGEMENT_NAME=//; s/^"//; s/"$//; s/\r$//')
  case "$DEFECTDOJO_ENGAGEMENTID" in
    ''|*[!0-9]*)
      echo "ERROR: invalid DEFECTDOJO_ENGAGEMENTID in defectdojo.env: $DEFECTDOJO_ENGAGEMENTID"
      return 1
      ;;
  esac
  DEFECTDOJO_ENGAGEMENT_NAME="${DEFECTDOJO_ENGAGEMENT_NAME:-Lab5 CI ${CI_PIPELINE_ID}}"
  export DEFECTDOJO_ENGAGEMENTID DEFECTDOJO_ENGAGEMENT_NAME
  return 0
}
