#!/bin/bash

REPO_PATH=$1
source ~/venv/boto3/bin/activate

# Get current dev HEAD
cd $REPO_PATH/boto3
git checkout develop
git pull

BOTO3_VERSION=$(head CHANGELOG.rst | grep -E '^[0-9.]+$')

pip install --upgrade -r requirements-docs.txt
cd docs
[[ -e build ]] && rm -rf build
make html

# There's an issue with sphinx < 1.3 so upgrade to latest
pip install --upgrade sphinx
[[ -e /var/tmp/boto3.docset ]] && rm -rf /var/tmp/boto3.docset
doc2dash -d /var/tmp/ --name boto3.docset build/html

[[ -e /var/tmp/boto3.docset.tgz ]] && rm -rf /var/tmp/boto3.docset.tgz
cd /var/tmp
tar -cvzf /tmp/boto3.tgz boto3.docset

# Get current HEAD
cd $REPO_PATH/Dash-User-Contributions/
git checkout kapeli
git pull
git checkout -b boto3-$BOTO3_VERSION
cd docsets/Boto3
[[ -e boto3.tgz.txt ]] && rm boto3.tgz.txt
cp /var/tmp/boto3.tgz .
OLD_VERSION=$(python -c "import json; print(json.loads(open('docset.json').read())['version'])")
echo "$(sed -e "s/$OLD_VERSION/$BOTO3_VERSION/" docset.json)" > docset.json
echo "$(sed -e "s/$OLD_VERSION/$BOTO3_VERSION/" README.md)" > README.md

git add README.md docset.json boto3.tgz.txt boto3.tgz
git commit -m "Updating Boto3 docset to version $BOTO3_VERSION"
git push

echo "Time for a pull request: https://github.com/angrychimp/Dash-User-Contributions"