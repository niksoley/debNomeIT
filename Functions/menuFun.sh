#!/bin/bash
#
#-------------------------------------------------------------------------------------------------#
####################  Menu Functions  ##################
#-------------------------------------------------------------------------------------------------#
#
## Main Menu ##
#-------------#
#
# Function to display the menu
display_menu() {
	clear
	echo "Menu:"
	for ((i=0; i<${#mainmenu_options[@]}; i++)); do
		echo  "$((i+1)). ${mainmenu_options[$i]}"
	done
}
#
# Main Menu function
menu() {
	while true; do
		menu_size=${#mainmenu_options[@]}
		display_menu
		read -p "Enter your choice (1-$menu_size): " choice
		if [ "$choice" -eq $((menu_size-1)) ]; then
        	generalView
		elif [ "$choice" -ge 1 ] && [ "$choice" -lt "$menu_size" ]; then
            index=$((choice-1))
			selected_option="${mainmenu_options[$index]}"
			submenuCall="${selected_option// /_}_options"
			declare -n submenu_array="$submenuCall"
			submenu
			exit
		elif [ "$choice" -eq "$menu_size" ]; then
			echo -e "\nExiting..."
			exit 0
		else
			echo "Invalid choice. Please enter a number between 1 and $menu_size."
		fi
	done
}
#
## Sub Menu ##
#------------#
#
# Array to store the state of each submenu option
declare -A states
#
# Function to toggle the state of an submenu option
toggle_state() {
	state=$1
	if ${states[$state]}; then
        states[$state]=false
	else
        states[$state]=true
	fi
}
#
# Function to toggle all states in the submenu
toggle_all_states() {
    all_marked=true
    
    # Check if all items are currently marked
    for state in "${submenu_array[@]}"; do
        if ! ${states[$state]}; then
            all_marked=false
            break
        fi
    done

    # Toggle all items based on whether they are all marked or not
    for state in "${submenu_array[@]}"; do
        if $all_marked; then
            states[$state]=false  # Unmark all
        else
            states[$state]=true   # Mark all
        fi
    done
}

# Function to display sub menu
display_submenu() {
	type=2
	case $type in
		1)
			for state in "${submenu_array[@]}"; do
			echo -n "($(
				if ${states[$state]}; then echo "X"; else echo " "; fi
				)) install ($(
				if ${states[$state]}; then echo " "; else echo "X"; fi
				)) uninstall $state"
				echo ""
			done
		;;
		2)
			for subindex in "${!submenu_array[@]}"; do
				state="${submenu_array[subindex]}"
				echo -n "$((subindex+1)).($(if ${states[$state]}; then echo "X"; else echo " "; fi)) $state"
				echo ""
			done
	esac
}
#
subMenuChoice() {
		case $subchoice in
			r|R)
                menu "${mainmenu_options[@]}"
            ;;
            [0-9]*)
                if (( subchoice >= 1 )) && (( subchoice <= ${#submenu_array[@]} )); then
					index=$((subchoice - 1))
					state=${submenu_array[$index]}
					toggle_state "$state"
				else
				echo "Invalid choice. Please enter a number from 1 to ${#submenu_array[@]}."
					sleep 2
				fi
            ;;
			e|E)
                # Loop through the submenu_array and execute functions with state "true"
                for state in "${submenu_array[@]}"; do
                    if ${states[$state]}; then
						execFun="${state// /_}"
						$execFun
                    fi
                done
                read -p "Execution finished. Press any key to continue..."
			;;
			m|M)
                if [ "$selected_option" != "General View" ]; then
                    # Toggle all items
                    toggle_all_states
                else
                    echo "Invalid choice. Please enter a number from 1 to ${#submenu_array[@]} or 'r' to return."
                fi
            ;;
            *)
                echo "Invalid choice. Please enter a number from 1 to ${#submenu_array[@]} or 'r' to return."
                sleep 2
			;;
        esac
}
# Main Submenu Loop
submenu() {
	while true; do
        clear
		echo "${selected_option}:"
        display_submenu
		echo ""
        read -p "$(echo -e "Enter the number corresponding to the application you want to toggle, ${Green}'e'${NC} to execute or ${Blue}'r'${NC} to return or ${Red}'m'${NC} to mark/unmark all: ")" subchoice
		echo ""
		subMenuChoice "$subchoice"
	done
}
#
# Function to view all submenu states
display_generalView() {
    for main_option in "${mainmenu_options[@]}"; do
        local submenu_name="${main_option// /_}_options"
        # Check if the submenu array exists
        if declare -p "$submenu_name" &> /dev/null; then
            declare -n submenu_array="$submenu_name"
            echo -e "\n${BrownBold}$main_option:${NC}"
            for state in "${submenu_array[@]}"; do
                echo -n "($(if ${states[$state]}; then echo "X"; else echo " "; fi)) $state"
				echo ""
            done
        fi
    done
}

generalView() {
	while true; do
		clear 
		echo "All Submenu Options and States:" 
		display_generalView
		echo ""
		read -p "$(echo -e "Enter ${Green}'e'${NC} to execute selected functions or ${Blue}'r'${NC} to return: ")" subchoice
		echo ""
		if [[ "$subchoice" =~ ^[eE]$ ]]; then
			for main_option in "${mainmenu_options[@]}"; do
			local submenu_name="${main_option// /_}_options"
				# Check if the submenu array exists
				if declare -p "$submenu_name" &> /dev/null; then
					declare -n submenu_array="$submenu_name"
					for state in "${submenu_array[@]}"; do
						if ${states[$state]}; then
							execFun="${state// /_}"
							$execFun
						fi
					done
				fi
            done
            read -p "Execution finished. Press any key to continue..."
		elif [[ "$subchoice" =~ ^[rR]$ ]]; then
			subMenuChoice "$subchoice"
		else
			echo "Invalid choice. Please enter 'e' to execute or 'r' to return."
			sleep 2
			display_generalView
		fi
	done
}
