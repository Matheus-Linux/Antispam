## Sistema de Antispam Open Source

Este documento tem como objetivo descrever e documentar a estrutura funcional do ambiente SMTP implantado. Destina-se exclusivamente a profissionais da área de Tecnologia da Informação e estudantes interessados na administração de serviços de correio eletrônico.

---

## Principais Funcionalidades

- Proteção do ambiente SMTP contra **spam**, **vírus** e **phishing**
- Atuação como **cache de e-mails**, reduzindo a carga nos servidores de relay e aumentando a eficiência do sistema

---

## Tecnologias Empregadas

- **Linux**  
- **Postfix**  
- **MailScanner**  
- **SpamAssassin**  
- **ClamAV**  
- **SASL**  
- **LDAP**  
- **DKIM**

---

## Principais Comandos Utilizados

```shell
# Verifica a fila de e-mails
mailq

# Exibe o conteúdo de uma mensagem a partir do ID
postcat -vq <ID>

# Consulta configurações específicas do Postfix
postconf <conf-name>

# Remove todas as mensagens da fila
postsuper -d all

# Força o reenvio das mensagens pendentes
postfix flush
```
## Máquinas Utilizadas

- **MPFXHAHOM01** – Máquina exclusiva para redirecionamento de conexões SMTP e STARTTLS  
- **MPFXSPAHOM01** – Máquina exclusiva para função de antispam  
- **MPFXSPAHOM02** – Máquina exclusiva para função de antispam  
- **MRLPFXHOM01** – Máquina exclusiva para função de mail relay  
- **MRLPFXHOM02** – Máquina exclusiva para função de mail relay

---

## Principais Arquivos de Configuração

- `/etc/postfix/main.cf` – Arquivo com as principais configurações do Postfix  
- `/etc/postfix/master.cf` – Arquivo com as configurações e propriedades do daemon do Postfix  
- `/etc/MailScanner/MailScanner.conf` – Arquivo com as principais configurações do MailScanner  
- `/etc/MailScanner/rules/blacklist.rules` – Arquivo com regras de blacklist de e-mails  
- `/etc/MailScanner/rules/spam.whitelist.rules` – Arquivo com regras de whitelist de e-mails  
- `/etc/MailScanner/rules/max.message.size.rules` – Arquivo para definir o tamanho máximo de uma mensagem  
- `/etc/MailScanner/mcp/` – Diretório com regras de MCP personalizadas  
- `/etc/MailScanner/archives.filename.rules.conf` – Arquivo com regras de bloqueio de arquivos compactados em anexo  
- `/etc/MailScanner/filename.rules.conf` – Arquivo para regras de bloqueio de arquivos em anexo

---

## Topologia do Ambiente

![Image](https://github.com/user-attachments/assets/d78da0c7-86b6-48d0-be84-48a7df861dfe)


