#!/bin/sh
# Source after load_defectdojo_env: . ./ci/load-defectdojo-env.sh && load_defectdojo_env
import_zap_report() {
  REPORT_FILE="$1"
  TEST_TITLE="$2"
  if [ ! -f "$REPORT_FILE" ]; then
    echo "Skip ZAP import: ${REPORT_FILE} not found"
    return 0
  fi
  echo "ZAP import: ${REPORT_FILE} -> engagement ${DEFECTDOJO_ENGAGEMENTID}"
  HTTP=$(curl -S -o zap-import-response.json -w "%{http_code}" \
    -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
    -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
    -F "scan_type=ZAP Scan" \
    -F "engagement=${DEFECTDOJO_ENGAGEMENTID}" \
    -F "file=@${REPORT_FILE}" \
    -F "test_title=${TEST_TITLE}" \
    -F "minimum_severity=Low" \
    -F "active=true" \
    -F "verified=false") || return 1
  echo "import-scan HTTP ${HTTP}"
  cat zap-import-response.json
  case "$HTTP" in
    200|201) echo "ZAP import OK: ${REPORT_FILE}" ;;
    *)
      echo "ERROR: ZAP import HTTP ${HTTP} for ${REPORT_FILE}"
      return 1
      ;;
  esac
}
