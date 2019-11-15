SHOW VARIABLES LIKE 'validate_password%';
set global validate_password_policy=0;
set global validate_password_length=4;
SHOW VARIABLES LIKE 'validate_password%';

CREATE DATABASE If Not Exists ambari DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  ambari.* TO 'ambari'@'%' IDENTIFIED BY 'ambari8899';

CREATE DATABASE If Not Exists oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  oozie.* TO 'oozie'@'%' IDENTIFIED BY 'oozie8899';

CREATE DATABASE If Not Exists hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive8899';

CREATE DATABASE If Not Exists ranger DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON ranger.* TO 'ranger'@'%' IDENTIFIED BY 'ranger8899';

CREATE DATABASE If Not Exists rangerkms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON rangerkms.* TO 'rangerkms'@'%' IDENTIFIED BY 'rangerkms8899';

flush privileges;
