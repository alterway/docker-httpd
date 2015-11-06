# Docker HTTPD

## Version available

- HTTPD/2.4 (docker tags: `2.4`) - `docker pull alterway/httpd:2.4`

## Presentation

The entrypoint run `httpd` daemon by default and expose port 80.

The default workdir is `/var/www/` and the default Apache DocumentRoot path is `/var/www/html`.


## Environment variables

### Set your httpd.conf

The apache configuration is dynamic. Just add environment variable with prefix `HTTPD__`.

Example with docker-compose :

    ...
    environment:
        HTTPD__DocumentRoot: '/var/www/public'
        HTTPD__ServerAdmin: 'webmaster@example.org'
        HTTPD__AddDefaultCharset: 'UTF-8'
        HTTPD__DirectoryIndex: 'app.php'

### Advanced Environment variables

- `HTTPD_Directory_AllowOverride` : Types of directives that are allowed in .htaccess files. Default `All`
- `HTTPD_Directory_Options` : Configures what features are available in a particular directory. Default `Indexes FollowSymLinks`
- `HTTPD_a2enmod`: Load Apache modules

See [https://httpd.apache.org/docs/2.4/en/mod/core.html](https://httpd.apache.org/docs/2.4/en/mod/core.html) for more informations

Example with docker-compose :

    ...
    environment:  
        HTTPD_Directory_AllowOverride: 'All'
        HTTPD_Directory_Options: 'Indexes FollowSymLinks'
    

### Load Apache modules
 
The apache modules are load on start. Just add environment variable `HTTPD_a2enmod` with list of your modules

Example with docker-compose :

    environment:    
        HTTPD_a2enmod:  'rewrite status expires'


## Use docker links

Set link with alias :

- `phpfpm` : set using mod_proxy_fcgi and FastCGI Process Manager PHPFPM processing php files


## Contributors

- [Nicolas Berthe](https://github.com/4devnull)



## License

View [LICENSE](LICENSE) for the software contained in this image.

