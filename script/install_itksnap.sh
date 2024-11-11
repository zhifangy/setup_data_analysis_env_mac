#!/bin/bash
set -e

# Get setup and script root directory
if [ -z "${SETUP_PREFIX}" ]; then
    echo "SETUP_PREFIX is not set or is empty. Defaulting to \${HOME}/Softwares."
    export SETUP_PREFIX='${HOME}/Softwares'
fi
# Set environment variables
INSTALL_PREFIX="$(eval "echo ${SETUP_PREFIX}/itksnap")"
ITKSNAP_VERSION=${ITKSNAP_VERSION:-4.2.0}
ITKSNAP_DATE=${ITKSNAP_DATE:-20240422}

# Cleanup old installation
if [ -d ${INSTALL_PREFIX} ]; then rm -rf ${INSTALL_PREFIX}; fi

# Install
echo "Installing ITK-SNAP from SourceForge..."
mkdir -p ${INSTALL_PREFIX}
wget -q https://sourceforge.net/projects/itk-snap/files/itk-snap/${ITKSNAP_VERSION}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg \
    -P ${INSTALL_PREFIX}
7zz x ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg -o"${INSTALL_PREFIX}/" \
    itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64/ITK-SNAP.app > /dev/null
mv ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64/ITK-SNAP.app ${INSTALL_PREFIX}/ITK-SNAP.app

# Put app to /Applications folder
if [[ -d /Applications/ITK-SNAP.app || -L /Applications/ITK-SNAP.app ]]; then rm /Applications/ITK-SNAP.app; fi
ln -s ${INSTALL_PREFIX}/ITK-SNAP.app /Applications/ITK-SNAP.app

# Symlink binary files
mkdir -p ${INSTALL_PREFIX}/bin
bin_list=("greedy" "greedy_template_average" "itksnap" "itksnap-wt" "multi_chunk_greedy")
for p in "${bin_list[@]}"; do
    ln -s ${INSTALL_PREFIX}/ITK-SNAP.app/Contents/bin/${p} ${INSTALL_PREFIX}/bin/${p}
done

# Cleanup
rm ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64.dmg
rm -r ${INSTALL_PREFIX}/itksnap-${ITKSNAP_VERSION}-${ITKSNAP_DATE}-Darwin-arm64

# Add following lines into .zshrc
echo "
Add following lines to .zshrc:

# ITKSNAP
export PATH=\"${SETUP_PREFIX}/itksnap/bin:\${PATH}\"
"
