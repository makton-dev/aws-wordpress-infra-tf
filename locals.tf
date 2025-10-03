locals {

  # dynamically make apache config with site domain name
  apache_conf = <<EOT
<VirtualHost *:80>
    ServerName ${var.domain_name}
    ServerAdmin webmaster@${var.domain_name}
    DocumentRoot /mnt/efs/${var.domain_name}

    <Directory /mnt/efs/${var.domain_name}>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /mnt/efs/${var.domain_name}/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
    </FilesMatch>

    LogLevel warn
    ErrorLog /var/log/httpd/${var.domain_name}/error.log
    CustomLog /var/log/httpd/${var.domain_name}/access.log combined

    # # For using Redis or Memcache
    # CacheEnable memcache
    # MEMCacheServer 127.0.0.1:11211
</VirtualHost>
EOT

  # comming part of the scripts.
  efs_mount_script = <<EOT
sudo wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
sudo python3 /tmp/get-pip.py
sudo pip3 install botocore || sudo /usr/local/bin/pip3 install botocore
sudo mkdir /mnt/efs
sudo mount -t efs -o tls,accesspoint=${aws_efs_access_point.efs_access.id} ${aws_efs_file_system.efs.id}:/ /mnt/efs
  EOT

  #   # local for WebServer starting script
  web_launch_script = <<EOT
#!/bin/bash
sudo dnf update -y
sudo dnf install -y amazon-efs-utils mariadb1011-client-utils wget httpd php-mysqlnd php-fpm php-json php php-xml php-curl php-mbstring php-zip php-intl php-bcmath php-gd ImageMagick ImageMagick-devel php-devel php-pear gcc
${local.efs_mount_script}
export PHP_MODULES="$(php -i | grep extension_dir | grep -o -m1 /usr/lib64/php*/modules | head -1)"
sudo pecl update-channels
sudo pecl install imagick
sudo chmod +x $PHP_MODULES/imagick.so
mkdir /mnt/efs/${var.domain_name}
sudo aws s3 cp s3://${aws_s3_bucket.launch_files_bucket.id}/${var.domain_name}.conf /etc/httpd/conf.d/
sudo aws s3 cp s3://${aws_s3_bucket.launch_files_bucket.id}/30-imagick.ini /etc/php.d/
sudo aws s3 cp s3://${aws_s3_bucket.launch_files_bucket.id}/www.conf /etc/php-fpm.d/
sudo aws s3 cp s3://${aws_s3_bucket.launch_files_bucket.id}/health-check.html /mnt/efs/${var.domain_name}/
sudo mkdir /var/log/httpd/${var.domain_name}
sudo systemctl enable --now httpd php-fpm
sudo systemctl restart httpd php-fpm
  EOT

  #   # Local for the JumpBox starting script
  jb_launch_script = <<EOT
#!/bin/bash
sudo dnf update -y
sudo dnf install -y amazon-efs-utils mariadb1011-client-utils wget
${local.efs_mount_script}
  EOT

}
