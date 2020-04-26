#!/bin/bash
# Script de backup das VM's Xen-Server (VM's a QUENTE)
####################################################################################
# Criado por: Rafael Oliveira #
# V.1.00 - Abril-2017
# Script original => 
# https://rafaelit.wordpress.com/2017/04/25/script-de-backup-a-quente-de-multiplas-vms-no-xen-server-7/
# ==================================================================================
# Modificado por: Vagner Cezarino 
# V.2.00 - Abril/2020
####################################################################################

# Comando xe sr-list no console do host XenServer lista UUIDs
#arrayvms=(Joe Curly Moe) # Nome das VMs a serem backupeadas

# Declaração de Variaveis ###############################################################

# Variaveis fixas, não alterar
dtbkp=`date +%Y%m%d` # data completa do backup para nome dos arquivos.
dataarq=`date +%Y%m%d` # data para numenclatura do arquivo de log.
datain2=`date +%s` # data usada para subtracao de tempo final da execução do script
bkpdestino=/mnt/backup # Caminho para armazenamento do backup
backupDay=`date +%A` #Define dia atual para buscar quais backups serão criados
i=0 # Contador de VMs para resumo final do backup no log

# Variaveis de configuração, alterar de acordo com uso
storageSnapshot="UUID_STORAGE" # Storage XenServer que armazena as VMs.
pathBackup="//IPBACKUP/PASTABACKUP" #Caminho de rede do servidor e pasta de Backup
arqLog="/mnt/backup/_log/bkpvms${dataarq}.log" #Arquivo de log, criar a subpasta _log na pasta de backup
numBackups="1,2d" # Quantidade de backups antigos (2 dia=2d) em retenção no Servidor de bkp
winUser="USUARIO_WINDOWS" # Usuario com permissão de escrita no servidor de backup
winPwd="SENHA_USUARIO" # Senha do usuário do servidor de backup
winDomain="DOMINIO_SERVIDOR_BACKUP" # Dominio do servidor de backup
# Partição na storage local para análise de espaço disponivel
particao="/dev/mapper/XSLocalEXT--e2911ee6--9248--4fcb--2eeb--3a5499cca78e-e2911ee6--9248--4fcb--2eeb--3a5499cca78e" 
maxStorageUse=80 #Valor máximo de uso da storage local para prosseguir com backup (em %)

#Desmonta unidade de backup caso a mesma esteja montada para testar conexão de rede
umount /mnt/backup

# Cria o diretorio que armazena backup e o log, caso não exista ##############################
if test -d /mnt/backup; then echo ""; else mkdir -p /mnt/backup; fi;

# Monta unidade de backup
mount -t cifs -o username=${winUser},password=${winPwd},domain=${winDomain} ${pathBackup} /mnt/backup -vvv

# Verifica se rede está acessível antes de iniciar, para não gravar no HD Local
if test -f /mnt/backup/backup.txt; then { 
	echo "Conectado ao servidor de backup"
} else {
	echo "ERRO Conectando ao servidor de backup"
 	exit 1	
} fi;

echo "Iniciando backup em ${dtbkp}..." >> ${arqLog}

# Verifica %uso da Storage de armazenamento local 
usoStorage=`df -h ${particao} | tail -1 | awk '{print $5}'| sed "s/%//g"`
echo "Storage local esta com "${usoStorage}"% de uso!" >> ${arqLog}
echo "Storage local esta com "${usoStorage}"% de uso!"
if [ "${usoStorage}" -gt "${maxStorageUse}" ]; then {
	echo "Processo abortado!" >> ${arqLog}
	echo "Storage local esta com "${usoStorage}"% de uso! Processo abortado!" 
	exit 1
} fi;

# Inicio do processo ###############################################################
echo "==============================================================================" > ${arqLog}
# Corrige Enter no final do arquivo texto das VMs x dia de backup
perl -pi -e 's/\r/\n/g' /mnt/backup/backup.txt 
# Le arquivo de VMs x dia de backup
arrayvms=`grep -i ${backupDay} /mnt/backup/backup.txt | cut -d'=' -f2` 
# Lista VMs a para backup no Log 
echo "Backup das VMs: " >> ${arqLog}
echo "${arrayvms[*]}" >> ${arqLog}

# For de backup ####################################################################
for vmname in ${arrayvms[*]} 
do {
	#Inicia variáveis
	i=$(($i+1))
	dhvm=`date +%d/%m/%Y_%H:%M:%S` # data completa de informacao de cada etapa.
	datain=`date +%s` # data usada para subtracao de tempo de cada vm.
	# Aguarda 10 segundos antes de iniciar o bkp.
	sleep 1 
	echo "==============================================================================" >> ${arqLog}
	echo "Iniciando backup da VM ${vmname} em ${dhvm}" >> ${arqLog}
	data=`date +%c` # Data e hora atual.
	 
	#Verifica se existe snapshot previo da VM e apaga
	echo "1. Verificando snapshot prévio em ${data}" >> ${arqLog}
	snapOld=$(xe snapshot-list snapshot-of=$(xe vm-list name-label=${vmname} --minimal) name-label="${vmname}_backup" --minimal | sed 's/,/ /g')
	for i in $snapOld ; do
		xe snapshot-destroy uuid=$i >> ${arqLog}
	done
	
	#Cria novo snapshot da VM
	echo "2. Cria snapshot da maquina em ${data}" >> ${arqLog}
	idvm=`xe vm-snapshot vm=${vmname} new-name-label=${vmname}_backup` &>> ${arqLog}
	if [ $? -eq 0 ]; then {
		echo "	Id Snapshot criado: ${idvm}" >> ${arqLog}

		#Converte Snapshot criado para Template 
		data=`date +%c` # Data e hora atual.
		xe template-param-set is-a-template=false uuid=${idvm} &>> ${arqLog}
		if [ $? -eq 0 ]; then {
			echo "3. Snapshot convertido em template em ${data}" >> ${arqLog}
		} else {
		 	echo "3. ERRO na criação do template." >> ${arqLog}
		 	exit 1
		} fi;

		#Converte Template criado para VM
		data=`date +%c` # Data e hora atual.
		cvvm=`xe vm-copy vm=${vmname}_backup sr-uuid=${storageSnapshot} new-name-label=${vmname}_${dtbkp}` &>> ${arqLog}
		if [ $? -eq 0 ]; then {
		 	echo "4. Template convertido em VM em ${data}" >> ${arqLog}
		} else {
		 	echo "4. ERRO na conversão do template da VM ${vmname}." >> ${arqLog}
		 	exit 1
		} fi;

		#Exporta VM para unidade de backup
		data=`date +%c` # Data e hora atual.
		if test -d ${bkpdestino}/${vmname}; then { # Se existir o diretorio
		 	# Se existe arquivo xva igual na pasta, apaga
		 	if test -f ${bkpdestino}/${vmname}/${vmname}_${dtbkp}.xva; then { 
		 		rm -f ${bkpdestino}/${vmname}/${vmname}_${dtbkp}.xva
		 	} fi;
		 	xe vm-export vm=${cvvm} filename="${bkpdestino}/${vmname}/${vmname}_${dtbkp}.xva" &>> ${arqLog}
		} else { # Se não existir o diretorio, cria um.
		 	mkdir -p ${bkpdestino}/${vmname}
		 	echo "	 Criando diretorio ${bkpdestino}/${vmname}" >> ${arqLog}
		 	xe vm-export vm=${cvvm} filename="${bkpdestino}/${vmname}/${vmname}_${dtbkp}.xva" &>> ${arqLog}
		} fi; 
		if [ $? -eq 0 ]; then {
		 	echo "5. Exportação concluida em ${data}." >> ${arqLog}
		} else {
		 	echo "5. ERRO na exportação da VM ${vmname}." >> ${arqLog}
		 	exit 1
		} fi;

		#Apaga VM e VDI temporários
		data=`date +%c` # Data e hora atual.
		xe vm-uninstall vm=${cvvm} force=true &>> ${arqLog}
		if [ $? -eq 0 ]; then {
			echo "6. VM e VDI temporários apagados com sucesso em ${data}." >> ${arqLog}
		} else {
		 	echo "6. ERRO ao deletar VM e VHD na VM ${vmname}." >> ${arqLog}
		 	exit 1
		} fi;

		#Apaga Snapshot
		data=`date +%c` # Data e hora atual.
		xe vm-uninstall --force uuid=${idvm} &>> ${arqLog}
		if [ $? -eq 0 ]; then {
			echo "7. Snapshot apagado em ${data}." >> ${arqLog}
		} else {
		 	echo "7. ERRO ao deletar Snapshot." >> ${arqLog}
		 	exit 1
		} fi;

		#Apaga backups antigos
		data=`date +%c` # Data e hora atual.
		ls -td1 ${bkpdestino}/${vmname}/* | sed -e ${numBackups} | xargs -d '\n' rm -rif &>> ${arqLog}
		if [ $? -eq 0 ]; then {
		 	echo "8. Backups antigos apagados em ${data}." >> ${arqLog}
		 	echo "	 Concluido Backup VM ${vmname} em ${data}." >> ${arqLog}
		} else {
		 	echo "8. ERRO ao excluir backups antigos." >> ${arqLog}
		 	exit 1
		} fi;

		#Calcula tempo de execução do backup da VM
		dataoud=`date +%s` #data final de execução
		seg=$((${dataoud} - ${datain}))
		min=$((${seg}/60))
		seg=`printf %02d $((${seg}-${min}*60))`
		hor=`printf %02d $((${min}/60))`
		min=`printf %02d $((${min}-${hor}*60))`
		echo "Tempo estimado: ${hor}:${min}:${seg}" >> ${arqLog}
		echo "==============================================================================" >> ${arqLog}
		bkpOk=${bkpOk}" "${vmname}
	} else {
		#Erro na criação do Snapshot - VM não localizada
		echo "1. ERRO: Não foi possível criar o Snapshot da VM ${vmname}." >> ${arqLog}
		echo "==============================================================================" >> ${arqLog}
		echo " " >> ${arqLog}
		bkpErr=${bkpErr}" "${vmname}
	} fi;

} done;

#Apaga arquivos de log 15 dias
data=`date +%c` # Data e hora atual.
ls -td1 ${bkpdestino}/_log/* | sed -e "1,15d" | xargs -d '\n' rm -rif &>> ${arqLog}
if [ $? -eq 0 ]; then {
 	echo "9. Arquivos de logs antigos apagados em ${data}." >> ${arqLog}
} fi;

#Calcula tempo total de todos os backups do dia
dataoud=`date +%s` #data final de execução
seg=$((${dataoud} - ${datain2}))
min=$((${seg}/60))
seg=`printf %02d $((${seg}-${min}*60))`
hor=`printf %02d $((${min}/60))`
min=`printf %02d $((${min}-${hor}*60))`

#Grava informações finais no Log
echo " " >> ${arqLog}
echo "Resumo:" >> ${arqLog}
echo "Total de VMs selecionadas no dia: ${i}" >> ${arqLog}
echo "VMs Ok   : ${bkpOk}" >> ${arqLog}
echo "VMs ERRO : ${bkpErr}" >> ${arqLog}
echo "Tempo Total Estimado: ${hor}:${min}:${seg}" >> ${arqLog}
echo "==============================================================================" >> ${arqLog}
echo "Desconectado do servidor de backup"

#Desmonta unidade de backup
umount /mnt/backup

exit 0
