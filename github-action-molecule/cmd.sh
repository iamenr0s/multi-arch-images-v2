#!/bin/sh

echo "ACTION: Welcome to the molecule action."

retry() {
 counter=0
 until "$@" ; do
 exit=$?
 counter=$((counter + 1))
 echo "ACTION: Retry attempt ${counter}/${max_failures:-3}."
 if [ "$counter" -ge "${max_failures:-3}" ] ; then
 return $exit
 fi
 done
 return 0
}

cd "${GITHUB_REPOSITORY:-.}" || exit

if [ -f tox.ini ] && [ "${command:-test}" = test ] ; then
 echo "ACTION: Running (retry) tox."
 retry tox
else
 echo "ACTION: Running (retry) molecule."
 PY_COLORS=1 ANSIBLE_FORCE_COLOR=1 retry molecule "${command:-test}" --scenario-name "${scenario:-default}"
fi || status="failed"

if [ "${status}" = "failed" ] ; then
 echo "ACTION: Thanks for using this action, good luck troubleshooting."
 exit 1
else
 echo "ACTION: Thanks for using this action."
fi
