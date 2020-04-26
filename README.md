# Sady-XenBackup V.2.00 - Abril/2020
Script de backup para XenServer 7.x 

O script é executado automaticamente todos os dias no mesmo horário no host XenServer através do Crontab (espécie de agendador de tarefas do Linux).

No script original todas as vms cadastradas participavam do processo de backup. A principal mudança foi permitir a pessoas, sem conhecimento de Linux, agendar as vms e respectivos dias da semana de backup destas, através de modificação de um simples arquivo txt no servidor de backup.

Outra melhoria foi, antes de iniciar o processo, identificar a disponibilidade de servidor externo, para evitar que os arquivos sejam acumulados na storage local, causando travamento no host por falta de
espaço.

Mais uma melhoria foi a verificação da % de uso da storage onde são criados os arquivos temporários de snapshot e nova vm: se estiver com 80% (valor configurável) o backup não é iniciado e um alerta é gravado no log. Isso tenta impedir o travamento do host por falta de espaço em disco durante o backup.

Prosseguindo nesta linha, também foi implementado no código uma verificação de existência de snapshots de backup antigos (que não foram apagados por qualquer motivo). Caso seja encontrado algum, o mesmo é apagado para evitar que o script seja interrompido.

A seguir existe a criação de um snapshot da vm, independente dela estar ligada ou desligada. O snapshot é convertido para template e este, para uma nova vm desligada, que será exportada para um servidor de backup. Ao final do processo, os arquivos temporários são apagados.

Por fim, são mantidos apenas os últimos x backups da vm, sendo x um número parametrizável na configuração do script.

Todo o processo é gravado no servidor de backup em um arquivo de Log, mantido por 15 dias, que também grava os tempos de backup individual e total.

Outra melhoria foi resumir no final do Log quantas vms estavam previstas, quais tiveram sucesso e quais apresentaram erros no backup.

A ressalva é que o storage local deve possuir disponível no mínimo o dobro do espaço da vm em backup, porque é criado um snapshot e outra vm para exportação. 

Agradecimentos ao sr. Rafael Oliveira (https://rafaelit.wordpress.com/2017/04/25/script-de-backup-a-quente-de-multiplas-vms-no-xen-server-7/) que disponibilizou o código original e permitiu que eu realizasse as alterações acima descritas.


####################################################################################################

# Sady-XenBackup V.2.00 - April / 2020
Backup script for XenServer 7.x

The script is automatically executed every day at the same time on the XenServer host through Crontab (kind of Linux task scheduler).

In the original script, all registered vms participated in the backup process. The main change was to allow people, without Linux knowledge, to schedule the vms and the respective days of the week to backup them, by modifying a simple txt file on the backup server.

Another improvement was, before starting the process, to identify the availability of an external server, to prevent files from accumulating on the local storage, causing the host to crash due to lack of
space.

Another improvement was the verification of the% of use of the storage where the temporary snapshot files and new vm are created: if it is with 80% (configurable value) the backup is not started and an alert is recorded in the log. This tries to prevent the host from crashing due to lack of disk space during the backup.

Continuing in this line, a verification of the existence of old backup snapshots (which were not deleted for any reason) was also implemented in the code. If any are found, they are deleted to prevent the script from being interrupted.

Then there is the creation of a snapshot of the vm, regardless of whether it is on or off. The snapshot is converted to a template and this, to a new offline vm, that will be exported to a backup server. At the end of the process, the temporary files are deleted.

Finally, only the last x backups of the vm are kept, with x being a parameterizable number in the script configuration.

The entire process is recorded on the backup server in a Log file, maintained for 15 days, which also records the individual and total backup times.

Another improvement was to summarize at the end of the Log how many vms were expected, which were successful and which had errors in the backup.

The caveat is that local storage must have at least twice the space of the backup vm, because a snapshot and another vm are created for export.

Thanks to mr. Rafael Oliveira (https://rafaelit.wordpress.com/2017/04/25/script-de-backup-a-quente-de-multiplas-vms-no-xen-server-7/) who provided the original code and allowed me to make the changes described above.
