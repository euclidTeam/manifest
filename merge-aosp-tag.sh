#!/bin/bash
#
# AOSP tag merge script for ArrowOS
# Author: Adithya R (ghostrider-reborn)
# Modified-by: Mrick343
#
# Usage (from source root):
#    ./manifest/merge-tag.sh <TAG>

# Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
end=$'\e[0m'

REMOTE="euclid"
BRANCH="qpr3"

BLACKLIST="packages/apps/DeskClock packages/apps/Gallery2"

# verify tag
if [ -z "$1" ]; then
    echo -e "Unspecified tag!\nUsage: ./merge.sh <TAG>"
    exit 1
else
    TAG="$1"
fi

if ! wget -q --spider https://android.googlesource.com/platform/manifest/+/refs/tags/$TAG; then
    echo "Invalid tag: $TAG!"
    exit 1
fi

# fetch all existing repos
echo "${blu}Fetching list of repos to be merged...$end"
REPOS=$(repo forall -v -c "if [ \"\$REPO_REMOTE\" = \"$REMOTE\" ]; then echo \$REPO_PATH; fi")
echo $REPOS

# save root dir
src_root=$(pwd)

# initialize some files
for file in failed success unchanged merged_repos; do
    rm -f $file
    touch $file
done

# main
for repo in $REPOS; do echo;
    if [[ $BLACKLIST =~ $repo ]]; then
        echo -e "$repo is in blacklist, skipped"
        continue
    fi

    if ! grep -q -e "path=\"$repo\"" -e "name=\"$repo\"" manifest/default.xml; then
        echo "${red}$repo not found in AOSP manifest, skipping..."
        continue
    fi

    # this is where the fun begins
    echo "${blu}Merging ${repo}..."
    name=$(grep "path=\"$repo\"" manifest/default.xml | sed -e 's/.*name="//' -e 's/".*//')
    if [[ -z $name ]]; then
        name=$(grep "name=\"$repo\"" manifest/default.xml | sed -e 's/.*name="//' -e 's/".*//')
    fi

    git -C $repo checkout -q $BRANCH &> /dev/null || echo "${red}$repo checkout failed!"
    git -C $repo reset --hard $REMOTE/$BRANCH &> /dev/null

    if ! git -C $repo fetch -q https://android.googlesource.com/$name $TAG &> /dev/null; then
        echo "${red}$repo fetch failed!"
    else
        if ! git -C $repo merge FETCH_HEAD -q -m "Merge tag '$TAG' into $BRANCH" &> /dev/null; then
            echo "$repo" >> $src_root/failed
            echo "${red}$repo merge failed!"
        else
            if [[ $(git -C $repo rev-parse HEAD) != $(git -C $repo rev-parse $REMOTE/$BRANCH) ]] && [[ $(git -C $repo diff HEAD $REMOTE/$BRANCH) ]]; then
                echo "$repo" >> $src_root/success
                echo "${grn}$repo merged successfully!"

                # Record merged repo in a list
                echo "$repo" >> $src_root/merged_repos

                # Push the changes to the remote branch
                if ! git -C $repo push -q &> /dev/null; then
                    echo "${red}$repo push failed!"
                else
                    echo "${grn}$repo pushed successfully!"
                fi
            else
                echo "${end}$repo unchanged"
                echo "$repo" >> $src_root/unchanged
                git -C $repo reset --hard $REMOTE/$BRANCH &> /dev/null
            fi
        fi
    fi
done

if [ -s success ]; then
    echo -e "${grn}\nMerge succeeded in:$end"
    cat success
fi

if [ -s failed ]; then
    echo -e "$red \nThese repos failed merging:$end"
    cat failed
fi

# Display the list of successfully merged repos
if [ -s merged_repos ]; then
    echo -e "${grn}\nThe following repos were successfully merged:$end"
    cat merged_repos
fi

echo $end
