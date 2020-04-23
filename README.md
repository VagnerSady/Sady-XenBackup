# Sady-XenBackup V.1.00 - Abril/2020
Script de backup para XenServer 7.x 

Script de backup a quente que não necessita APIs, executado sem desligar a VM.

O arquivo bkpscript.sh é gravado no host XenServer na pasta /etc/init.d/script/bkpscript.sh com permissão chmod 775 (+x)

Configurável, permite parametrizar o servidor ou HD externo de destino do backup.

Ao habilitar o script no Crontab do Xenserver diariamente, é possivel definir através de um arquivo txt no servidor destino de backups os dias da semana para backup de cada VM.

O script cria um Snapshot para cada VM especificada no dia da sua execução, transforma o Snapshot em Template e em nova VM que será exportada para arquivo XVA (padrão do XenServer).

Após completar a operação, os arquivos temporários de Snapshot e Template são deletados e é gerado um Log com os tempos e status de execução dos backups.

O script verifica o destino do backup para evitar gravar o mesmo localmente e travar o host por falta de espaço.

Também analisa snapshots repetidos para a VM e apaga o mais antigo para evitar erro de duplicidade de nome.

Por fim, ao gravar o arquivo de backup no destino, ele permite configurar quantos backups anteriores irão existir, apagando os mais antigos.

=====================================================================================================================================

Backup Script for XenServer 7.x -  V.1.00 - April/2020

Hot backup script that does not require APIs, runs without shutting down a VM.

The bkpscript.sh file is saved on the XenServer host in the /etc/init.d/script/bkpscript.sh folder with permission chmod 775 (+ x)

Configurable, allows you to parameterize the server or external destination HD for backup.

By enabling the script on the daily Xenserver's Crontab, it is possible to define a txt file on the backup destination server on the days of the week for the backup of each VM.

The script creates a Snapshot for each VM specified on the day of its execution, transforms the Snapshot into the model and into the new VM that will be exported to the XVA file (XenServer standard).

After completing the operation, the temporary Snapshot and Template files are deleted and created as a Log with backup execution times and status.

The script checks the destination of the backup to avoid local recording and the host due to lack of space.

It also analyzes repeated snapshots for a VM and is older to avoid duplicate name errors.

Finally, when recording or backup file at the destination, it allows configuring how many previous backups will occur, deleting the oldest ones.

