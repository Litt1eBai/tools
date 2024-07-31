#!/bin/bash

# Detect Java directories in the current folder
declare -A JAVA_VERSIONS

# Look for directories containing 'bin' and 'java' executable
for dir in */; do
    if [[ -d "$dir/bin" && -f "$dir/bin/java" ]]; then
        # Trim trailing slash and set as JAVA_HOME
        java_dir="${dir%/}"
        # Generate an alias name based on the directory name, e.g., java8, java11
        alias_name="${java_dir//[^a-zA-Z0-9]/}"
        JAVA_VERSIONS[$alias_name]="$PWD/$java_dir"
    fi
done

# Configuration file to update (either ~/.bashrc or ~/.bash_profile)
CURRENT_SHELL=$(basename "$SHELL")
case "$CURRENT_SHELL" in
    bash)
        CONFIG_FILE="$HOME/.bashrc"
        ;;
    zsh)
        CONFIG_FILE="$HOME/.zshrc"
        ;;
    *)
        echo "Unsupported shell: $CURRENT_SHELL"
        exit 1
        ;;
esac

# Backup the original configuration file
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Add JAVA_HOME and PATH settings
# Add alias
{
    echo ""
    echo "# Java alias"
    for alias in "${!JAVA_VERSIONS[@]}"; do
        java_executable="${JAVA_VERSIONS[$alias]}"
        echo "alias $alias='$java_executable'"
    done

} >> "$CONFIG_FILE"

#Java environment variables
{
    echo ""
    echo "# Java environment variables"
    for alias in "${!JAVA_VERSIONS[@]}"; do
        java_home="${JAVA_VERSIONS[$alias]}"
        echo "export ${alias^^}_HOME=\"$java_home\""
    done

} >> "$CONFIG_FILE"

# Prompt user to select a Java version
echo "Please select the Java version to set as JAVA_HOME:"
index=1
for alias in "${!JAVA_VERSIONS[@]}"; do
    java_home="${JAVA_VERSIONS[$alias]}"
    echo "$index) $alias - $java_home"
    index=$((index + 1))
done

read -p "Enter the number of the Java version: " choice

index=1
selected_java_home=""
for alias in "${!JAVA_VERSIONS[@]}"; do
    if [ $index -eq $choice ]; then
        selected_java_home="${JAVA_VERSIONS[$alias]}"
        break
    fi
    index=$((index + 1))
done

if [ -z "$selected_java_home" ]; then
    echo "Invalid selection."
    exit 1
fi

# Add selected JAVA_HOME to the config file
{
    echo ""
    echo "# Selected JAVA_HOME"
    echo "export JAVA_HOME=\"$selected_java_home\""
    echo "export PATH=\$PATH:\$JAVA_HOME/bin"
} >> "$CONFIG_FILE"

# Apply the changes for the current session
source "$CONFIG_FILE"

echo "Java environment variables and aliases have been set up."
echo "Reload your shell or source $CONFIG_FILE to apply the changes."

