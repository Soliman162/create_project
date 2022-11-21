#! /bin/bash

project_name_init="init_dir"
project_name=${project_name_init}

declare -a ls_array=( `ls` )
declare -au HAL_array=()
declare -au MCAL_array=()

# check if project name is already exist
while [ ${project_name} = ${project_name_init} ]
do
    read -p "please enter project name : " project_name
    for dir in ${ls_array[@]}
    do 
        if [ ${project_name} = ${dir} ]
        then
            echo "PROJECT NAME IS REPEATED ,try again"
            project_name=${project_name_init}
            break
        fi
    done
done

# recieve the hardware modules
printf "please enter HAL modules:- 
      press Enter to stop: "
read -a HAL_array
# recieve the microcontroller modules
printf "please enter MCAL modules:- 
      press Enter to stop: "
read -a MCAL_array

# make dir for project folders
mkdir ${project_name}
mkdir ${project_name}/HAL
mkdir ${project_name}/MCAL
mkdir ${project_name}/APP
mkdir ${project_name}/APP/build
mkdir ${project_name}/LIB

# make files for hardware modules
cd ${project_name}/HAL

for module in ${HAL_array[@]}
do
    mkdir ${module}
    touch ${module}/${module}_interface.h
    touch ${module}/${module}_private.h
    touch ${module}/${module}_config.h
    touch ${module}/${module}_program.c
done

# make files for microcontroller modules
cd ../MCAL

for module in ${MCAL_array[@]}
do
    mkdir ${module}
    touch ${module}/${module}_interface.h
    touch ${module}/${module}_private.h
    touch ${module}/${module}_config.h
    touch ${module}/${module}_program.c
done

# make files for lib layer
cd ../LIB
cp /home/soliman/AVR/ATmega32/AVR_COTS/LIB/* .

# make files for App layer
cd ../APP 
touch main.c
touch CMakeLists.txt

echo "
CMAKE_MINIMUM_REQUIRED(VERSION 3.22)

PROJECT(${project_name})

set(CMAKE_GENERATOR CACHE STRING \"Unix Makefiles\")
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_CXX_COMPILER avr-g++ CACHE STRING \"C++ compiler\" FORCE)
set(CMAKE_C_COMPILER avr-gcc CACHE STRING \"C compiler\" FORCE)
set(CMAKE_OBJCOPY      avr-objcopy CACHE STRING \"avr-objcopy\" FORCE)
set(CMAKE_C_FLAGS \"-mmcu=atmega32 -O1 -DF_CPU=8000000UL \")


set(MCAL_PATH  \${CMAKE_CURRENT_SOURCE_DIR}/../MCAL )
set(HAL_PATH   \${CMAKE_CURRENT_SOURCE_DIR}/../HAL  )
">>  CMakeLists.txt

echo "add_executable( \${PROJECT_NAME}.elf 
                        \${CMAKE_CURRENT_SOURCE_DIR}/main.c" >> CMakeLists.txt

for module in ${HAL_array[@]}
do
    echo "              \${HAL_PATH}/${module}/${module}_program.c" >> CMakeLists.txt
done

for module in ${MCAL_array[@]}
do
    echo "              \${MCAL_PATH}/${module}/${module}_program.c" >> CMakeLists.txt
done 

echo ")  

target_include_directories( \${PROJECT_NAME}.elf PUBLIC " >> CMakeLists.txt

for module in ${HAL_array[@]}
do
    echo "              \${HAL_PATH}/${module}/" >> CMakeLists.txt
done

for module in ${MCAL_array[@]}
do
    echo "              \${MCAL_PATH}/${module}" >> CMakeLists.txt
done   
                            
echo "                  \${CMAKE_CURRENT_SOURCE_DIR}/../LIB

)     
 
add_custom_target(build ALL
                DEPENDS \${PROJECT_NAME}.elf
                COMMAND avr-objcopy -j .text -j .data -O ihex \${PROJECT_NAME}.elf \${PROJECT_NAME}.hex
                ) 
                
add_custom_target(flash 
                DEPENDS build 
                COMMAND  avrdude -c usbasp -p m32 -B 0.5 -U flash:w:\"\${PROJECT_NAME}.hex\":a 
)

add_custom_target(remove
                    COMMAND  rm -rf \${CMAKE_CURRENT_SOURCE_DIR}/build/*
)
" >>  CMakeLists.txt
