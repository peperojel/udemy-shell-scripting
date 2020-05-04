#!/bin/bash

# Refactor of add-local-user.sh
# Permite la creación de usuario indicando id y comentario como argumentos en la ejecución del script
# Se le asigna una contraseña segura de forma automática

# Verificar si el usuario tiene privilegios de root
if [[ "${UID}" -ne 0 ]]
then
    echo "You need root privileges..." 1>&2
    exit 1
fi

# Verificar que el usuario proveyó al menos un argumento
if [[ "${#}" -lt 1 ]]
then
  echo "Usage: ${0} USER_NAME [COMMENT]..." 1>&2
  echo "Create an account on the local system with the name of USER_NAME and a comments field of COMMENT." 1>&2
  exit 1
fi

# Asignar nombre de usuario y comentario (if exists)
USER_NAME="${1}"
shift

# if [[ "${#}" -ge 1 ]]
# then
#   COMMENT="${1}"
#   shift
#   while [[ "${#}" -gt 0 ]]
#   do
#     COMMENT+=" ${1}"
#     shift
#   done    
# fi
COMMENT="${@}"

# Creación del nuevo usuario
useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null

# Check for return of previous command
if [[ "${?}" -ne 0 ]]
then
    echo "Failed useradd execution" 1>&2
    exit 1
fi

# Generación de una password aleatoria segura
PASSWORD=$(date +%s%N | sha256sum | head -c48)
PASSWORD+=$(echo "#$%&/()=?_!" | fold -w1 | shuf | head -c1)

# Establecer password a usuario
echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null

# Verificar que el cambio de contraseña fue exitoso
if [[ "${?}" -ne 0 ]]
then
  echo "Failed setting the password" 1>&2
  exit 1
fi

# Forzar a que el usuario cambie su contraseña cuando ingrese
passwd -e ${USER_NAME} &> /dev/null

# Imprimir los resultados

echo "username:
${USER_NAME}

password:
${PASSWORD}

host:
$(hostname)"

exit 0