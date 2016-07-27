# Basic Authentication with Redmine
Apache mod_authnz_fcgi for Redmine.

## Usage:
### Get fcgiauthredmine.pl
```
cd /etc/apache2
sudo curl -O https://raw.githubusercontent.com/HimaJyun/mod_authnz_fcgi-for-redmine/master/fcgiauthredmine.pl
sudo chmod +x fcgiauthredmine.pl
```

### Get init script
```
cd /etc/init.d
sudo curl -O https://raw.githubusercontent.com/HimaJyun/mod_authnz_fcgi-for-redmine/master/fcgiauthredmine
sudo chmod +x fcgiauthredmine
```

### Dependency
This script uses the spawn-fcgi.  
`sudo apt-get install spawn-fcgi`  
mod_authnz_fcgi(Apache 2.4.10 and later)  
`sudo a2enmod authnz_fcgi`  

## Settings
### init script.
`sudo editor /etc/init.d/fcgiauthredmine`  
Setting items.  
```
# === config ===
# Path of fcgiauthredmine.pl
path="/etc/apache2/fcgiauthredmine.pl"
# pid file path
pid="/run/fcgiauthredmine.pid"
# Number of process
proc=3
# Port number.
port=8989
# Argument
args=(--dsn='DBI:mysql:database=redmine;host=localhost;mysql_socket=/run/mysqld/mysqld.sock' \
--user='root' \
--pass='123' \
--mysql_auto_reconnect)
# ==============
```

### Argument
Database connection string.  
`--dsn="string"`  
Database user.(Not required for SQLite)  
`--user="string"`  
Database password.(Not required for SQLite)  
`--pass="string"`  
Only MySQL, Automatically reconnect.(Recommend)  
`--mysql_auto_reconnect`  

### DSN string example.
For MySQL(socket:recommend)  
`DBI:mysql:database=${dbname};host=localhost;mysql_socket=${Socket path}`  
For MySQL(TCP)  
`DBI:mysql:database=${dbname};host=localhost;port=3306`  
For PostgreSQL  
`DBI:Pg:database=${dbname};host=localhost;port=5432`  
For SQLite(Deprecated)  
`DBI:SQLite:database=${db file path}`  

### Add a service
```sudo systemctl enable fcgiauthredmine```  

### Apache settings.
```
AuthnzFcgiDefineProvider authn AuthRedmine fcgi://localhost:8989/
<VirtualHost *:80>
    ServerName git.example.com
    DocumentRoot /var/www/git

    <Location />
        AuthType Basic
        AuthName "Git SmartHTTP"
        AuthBasicProvider AuthRedmine
        Require valid-user
    </Location>

</VirtualHost>
```
- AuthnzFcgiDefineProvider is server config only.(It can not be set in VirtualHost)  
- auth**n** only, auth**z** and auth**nz** can not be used.

### Restart
```
sudo systemctl restart fcgiauthredmine
sudo systemctl restart apache2
```
