#!/bin/bash

# Function to detect the package manager
function detect_package_manager {
  if command -v apt &>/dev/null; then
    echo "apt"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unsupported"
  fi
}

# Function to install dependencies
function install_dependencies {
  local package_manager=$1

  if [ "$package_manager" == "apt" ]; then
    sudo apt update
    sudo apt install -y zsh git
  elif [ "$package_manager" == "pacman" ]; then
    sudo pacman -Sy --noconfirm zsh git
  fi
}

# Install MesloLGS NF fonts
function install_fonts {
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"

  fonts=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
  )

  fonts_downloaded=false

  for font in "${fonts[@]}"; do
    font_name=$(basename "$font")
    if [ ! -f "$font_dir/$font_name" ]; then
      wget -q "$font" -P "$font_dir"
      fonts_downloaded=true
    fi
  done

  if [ "$fonts_downloaded" = true ]; then
    fc-cache -fv
  fi
}

# Function to install oh-my-zsh
function install_oh_my_zsh {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
  fi
}

# Function to install powerlevel10k theme
function install_powerlevel10k {
  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  fi
}

# Function to install zsh plugins
function install_zsh_plugins {
  plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$plugins_dir"

  if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
  fi

  if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
  fi
}

# Function to backup .zshrc file
function backup_zshrc {
  local zshrc_path="$1"
  local backup_path="${zshrc_path}.bak"
  cp "$zshrc_path" "$backup_path"
  echo "Backup created: $backup_path"
}

# Function to update .zshrc
function update_zshrc {
  local zshrc_path="$1"
  local theme="ZSH_THEME=\"powerlevel10k/powerlevel10k\""
  local plugins="plugins=(git zsh-syntax-highlighting zsh-autosuggestions)"

  # Prompt user to backup .zshrc
  read -p "Would you like to create a backup of your .zshrc before making changes? (y/n): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    backup_zshrc "$zshrc_path"
  fi

  #  # Update the plugins in .zshrc
  if grep -q "^plugins=" "$zshrc_path"; then
    sed -i 's/^plugins=.*/'"$plugins"'/' "$zshrc_path"
  else
    echo "$plugins" >> "$zshrc_path"
  fi

  # Check for existing ZSH_THEME line and update or add it
  if grep -q "^ZSH_THEME=" "$zshrc_path"; then
    sed -i '/^ZSH_THEME=/s|^ZSH_THEME=.*|'"$theme"'|' "$zshrc_path"
  else
    echo "$theme" >> "$zshrc_path"
  fi
}

# Main script
package_manager=$(detect_package_manager)

if [ "$package_manager" == "unsupported" ]; then
  echo "Unsupported package manager. Exiting."
  exit 1
fi

install_dependencies "$package_manager"

# Ask if the user wants to install the required fonts
read -p "Would you like to install the required fonts for powerlevel10k? (y/n): " install_fonts_response
if [[ "$install_fonts_response" =~ ^[Yy]$ ]]; then
  install_fonts
fi

install_oh_my_zsh
install_powerlevel10k
install_zsh_plugins

# Update .zshrc
zshrc="$HOME/.zshrc"
update_zshrc "$zshrc"

# Prompt user to change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  read -p "Would you like to set zsh as your default shell? (y/n): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to zsh. Please restart your terminal."
  else
    echo "Default shell not changed. You can manually change it later with 'chsh -s $(which zsh)'."
  fi
fi

# Done
echo "Installation complete!"
