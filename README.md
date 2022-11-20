<p align="center">
  <img src="https://hermes.digitalinnovation.one/tracks/7b035b91-8625-493c-a816-6740a4a25e9b.png" style="height: 200px; width:200px;"/>
</p>

# Jornada DevOps com AWS - Impulso - Projeto de IAC #2 do módulo *Conhecendo o Sistema Operacional Linux*

### O que este script faz?
Realiza o provisionamento do servidor WEB Apache, em distros Linux Debian like, com certificado SSL autoassinado. Todas as requisições HTTP serão redirecionadas para HTTPS.

### O que este script não faz?
Apesar do script configurar e ativar o SSL para o Apache, não foram tomadas outras medidas que ajudariam a melhorar a segurança e performance do servidor: foi dado enfoque à solicitação da tarefa do desafio de código da DIO.

Como utilizar este script?
```
wget https://raw.githubusercontent.com/ojpojao/dio-iac2-apache/main/install.sh
chmod +x install.sh
sudo ./install.sh
```
