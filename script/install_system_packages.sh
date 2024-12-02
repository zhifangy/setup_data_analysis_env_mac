#!/bin/bash
set -e

# Initialize environment
source "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/utils.sh" && init_setup


if [ "$OS_TYPE" == "macos" ]; then
# Install Homebrew
if [ -x "/opt/homebrew/bin/brew" ]; then
    echo "Homebrew is already installed."
    # check if /opt/homebrew/bin is in the PATH
    if ! echo "$PATH" | grep -q "/opt/homebrew/bin"; then
        echo "However, /opt/homebrew/bin is not in the \$PATH."
        echo "Temporarily adding it to \$PATH. Please modify the shell profile file to make it persistent."
        PATH="/opt/homebrew/bin:${PATH}"
    fi
else
    echo "Homebrew is not installed. Installing Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages
# private tap
brew tap rundel/quarto-cli
# formula packages
deps_formula=(
    "wget" "curl" "vim" "cmake" "gcc" "llvm" "autoconf" "tcl-tk" "pkgconf" "xz" "readline" "gettext" "icu4c" \
    "bzip2" "zlib" "node" "python" "open-mpi" "openblas" "libomp" "tbb" "openjdk" "freetype" "fontconfig" "libiconv" \
    "libpng" "jpeg" "gsl" "expat" "swig" "openmotif" "mesa" "mesa-glu" "libxt" "libxpm" \
    "hdf5" "texinfo" "mariadb-connector-c" "htop" "btop" "tree" "git" "sevenzip" "pandoc" \
    "rundel/quarto-cli/quarto" "autossh" "gromgit/fuse/sshfs-mac" "bash" "bat" "lsd" "fzf" "starship" "thefuck" "rclone"
)
# cask packages
deps_cask=("xquartz" "macfuse")
# get installed packages
installed_formulas=$(brew list --formula --full-name)
installed_casks=$(brew list --cask --full-name)
# find the missing packages
missing_formulas=()
missing_casks=()
for p in "${deps_formula[@]}"; do
    if ! echo "${installed_formulas}" | grep -q "^${p}\(@.*\)*$"; then
        missing_formulas[${#missing_formulas[@]}]="${p}"
    fi
done
for p in "${deps_cask[@]}"; do
    if ! echo "${installed_casks}" | grep -q "^${p}\(@.*\)*$"; then
        missing_casks[${#missing_casks[@]}]="${p}"
    fi
done
# install missing packages if any
if [ "${#missing_formulas[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_formulas[*]} ..."
    brew install "${missing_formulas[@]}"
fi
if [ "${#missing_casks[@]}" -gt 0 ]; then
    echo "Installing missing dependencies: ${missing_casks[*]} ..."
    brew install --cask "${missing_casks[@]}"
fi

# Cleanup
brew cleanup

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# Homebrew
eval \"\$(/opt/homebrew/bin/brew shellenv)\"
FPATH=\"\$(brew --prefix)/share/zsh/site-functions:\${FPATH}\"

# Starship
eval \"\$(starship init zsh)\"

# bat
export BAT_THEME=\"Dracula\"

# fzf
# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# The fuck
eval \"\$(thefuck --alias)\"

# Alias
# lsd
alias ll=\"lsd -l\"
alias la=\"lsd -a\"
alias lla=\"lsd -la\"
alias lt=\"lsd --tree\"
alias llsize=\"lsd -l --total-size\"
# fzf
alias preview=\"fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'\"
"


elif [ "$OS_TYPE" == "rhel8" ]; then
# Set environment variables
export MAMBA_ROOT_PREFIX="$(eval "echo ${INSTALL_ROOT_PREFIX}/micromamba")"
export \
    CONDA_ENVS_DIRS="${MAMBA_ROOT_PREFIX}/envs" \
    CONDA_PKGS_DIRS="${MAMBA_ROOT_PREFIX}/pkgs" \
    CONDA_CHANNELS="conda-forge,HCC"
SYSTOOLS_DIR="$(eval "echo ${INSTALL_ROOT_PREFIX}/systools")"

# Install Micromamba
if [ -x "${MAMBA_ROOT_PREFIX}/bin/micromamba" ]; then
    echo "Micromamba is already installed."
    # check if ${MAMBA_ROOT_PREFIX}/bin is in the PATH
    if ! echo "$PATH" | grep -q "${MAMBA_ROOT_PREFIX}/bin"; then
        echo "However, ${MAMBA_ROOT_PREFIX}/bin is not in the \$PATH."
        echo "Temporarily adding it to \$PATH. Please modify the shell profile file to make it persistent."
        PATH="${MAMBA_ROOT_PREFIX}/bin:${PATH}"
    fi
else
    echo "Installing Micromamba ..."
    mkdir -p ${MAMBA_ROOT_PREFIX} && curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | \
    tar -C ${MAMBA_ROOT_PREFIX} -xj bin/micromamba
fi

# Cleanup old installation
if [ $(micromamba env list | grep -c ${SYSTOOLS_DIR}) -ne 0 ]; then
    echo "Cleanup old environment ${SYSTOOLS_DIR}..."
    micromamba env remove -p ${SYSTOOLS_DIR} -yq
elif [ -d ${SYSTOOLS_DIR} ]; then
    echo "Cleanup old environment ${SYSTOOLS_DIR}..."
    rm -rf ${SYSTOOLS_DIR}
fi

# Create systools environment
echo "System tools enviromenmet location: ${SYSTOOLS_DIR}"
micromamba create -yq -p ${SYSTOOLS_DIR} -f ${SCRIPT_ROOT_DIR}/misc/systools.yml
# copy activate and deactivate script
cp ${SCRIPT_ROOT_DIR}/script/activate_systools.sh ${SYSTOOLS_DIR}/.
cp ${SCRIPT_ROOT_DIR}/script/deactivate_systools.sh ${SYSTOOLS_DIR}/.

# Fix zsh directory permission
chmod 755 ${SYSTOOLS_DIR}/share/zsh
chmod 755 $(ls -d ${SYSTOOLS_DIR}/share/zsh/*)
chmod 755 $(ls -d ${SYSTOOLS_DIR}/share/zsh/*)/functions

# Cleanup
micromamba clean -yaq

# Add following lines into .zshrc
echo "
Add following line to .zshrc

# Micromamba
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE=\"${INSTALL_ROOT_PREFIX}/micromamba/bin/micromamba\";
export MAMBA_ROOT_PREFIX=\"${INSTALL_ROOT_PREFIX}/micromamba\";
__mamba_setup=\"\$(\"\$MAMBA_EXE\" shell hook --shell zsh --root-prefix \"\$MAMBA_ROOT_PREFIX\" 2> /dev/null)\"
if [ \$? -eq 0 ]; then
    eval \"\$__mamba_setup\"
else
    alias micromamba=\"\$MAMBA_EXE\"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
export PATH=\"${INSTALL_ROOT_PREFIX}/micromamba/bin:\${PATH}\"
# configuration
export \\
    CONDA_ENVS_DIRS=\"\${MAMBA_ROOT_PREFIX}/envs\" \\
    CONDA_PKGS_DIRS=\"\${MAMBA_ROOT_PREFIX}/pkgs\" \\
    CONDA_CHANNELS=\"conda-forge,HCC\"

# Systools
export SYSTOOLS_DIR=\"${INSTALL_ROOT_PREFIX}/systools\"
export PATH=\"\${SYSTOOLS_DIR}/bin:\${SYSTOOLS_DIR}/x86_64-conda-linux-gnu/sysroot/usr/bin:\${PATH}\"

# Compiler configuration
source \${SYSTOOLS_DIR}/activate_systools.sh
export LD_LIBRARY_PATH=\"\${SYSTOOLS_DIR}/lib:\${SYSTOOLS_DIR}/x86_64-conda-linux-gnu/sysroot/usr/lib64:\${LD_LIBRARY_PATH}\"
export PKG_CONFIG_PATH=\"\${SYSTOOLS_DIR}/lib/pkgconfig:\${PKG_CONFIG_PATH}\"

# bat
export BAT_THEME=\"Dracula\"

# fzf
# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Direnv
eval \"\$(direnv hook zsh)\"

# Alias
# lsd
alias ll=\"lsd -l\"
alias la=\"lsd -a\"
alias lla=\"lsd -la\"
alias lt=\"lsd --tree\"
alias llsize=\"lsd -l --total-size\"
# fzf
alias preview=\"fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'\"
"
fi
