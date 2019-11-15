SHOW VARIABLES LIKE 'validate_password%';
set global validate_password_policy=0;
set global validate_password_length=4;
SHOW VARIABLES LIKE 'validate_password%';

CREATE DATABASE If Not Exists scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  scm .* TO 'scm'@'%' IDENTIFIED BY 'scm8899';

CREATE DATABASE If Not Exists amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  amon.* TO 'amon'@'%' IDENTIFIED BY 'amon8899';

CREATE DATABASE If Not Exists rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  rman .* TO 'rman'@'%' IDENTIFIED BY 'rman8899';

CREATE DATABASE If Not Exists hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  hue.* TO 'hue'@'%' IDENTIFIED BY 'hue8899';

CREATE DATABASE If Not Exists metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  metastore.* TO 'metastore'@'%' IDENTIFIED BY 'metastore8899';

CREATE DATABASE If Not Exists sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  sentry.* TO 'sentry'@'%' IDENTIFIED BY 'sentry8899';

CREATE DATABASE If Not Exists nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  nav.* TO 'nav'@'%' IDENTIFIED BY 'nav8899';

CREATE DATABASE If Not Exists navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  navms.* TO 'navms'@'%' IDENTIFIED BY 'navms8899';

CREATE DATABASE If Not Exists oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON  oozie.* TO 'oozie'@'%' IDENTIFIED BY 'oozie8899';

CREATE DATABASE If Not Exists hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive8899';

flush privileges;
