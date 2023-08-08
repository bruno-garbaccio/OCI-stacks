'use strict';

/**
 * Visual Builder application build script.
 * For details about the application build and Visual Builder-specific grunt tasks
 * provided by the grunt-vb-build npm dependency, please refer to
 * https://www.oracle.com/pls/topic/lookup?ctx=en/cloud/paas/app-builder-cloud&id=visual-application-build
 */
module.exports = (grunt) => {
    require('load-grunt-tasks')(grunt);

  grunt.config.init({
    variables: {
      OCI_USER: process.env.OCI_USER,
      OCI_PUBLIC_IP: process.env.OCI_PUBLIC_IP,
      OCI_SECRET_OCID: process.env.OCI_SECRET_OCID,
      OCI_SEARCHDATE: process.env.OCI_SEARCHDATE,
      OCI_PATH_CONF_FILE: process.env.OCI_PATH_CONF_FILE
    },
      OCI_APIGWURL: process.env.OCI_APIGWURL
  });

  grunt.registerTask('initVar', 'Initialize Variables files', function(){
    grunt.config.requires('variables.OCI_USER' );
    grunt.config.requires('variables.OCI_PUBLIC_IP' );
    grunt.config.requires('variables.OCI_SECRET_OCID' );
    grunt.config.requires('variables.OCI_SEARCHDATE' );
    grunt.config.requires('variables.OCI_PATH_CONF_FILE' );
    grunt.config.requires('OCI_APIGWURL' );

    grunt.log.writeln("=== Replace Backend ===");
    grunt.log.writeln("OCI_APIGWURL: " + process.env.OCI_APIGWURL);
    var catalog = JSON.parse(grunt.file.read('services/catalog.json'));
    catalog.backends.API_GATEWAY_BACKEND.servers[0].variables.APIGWURL.default = process.env.OCI_APIGWURL;

    grunt.log.writeln("New Catalog:"+JSON.stringify(catalog,null,2));
    grunt.file.write('services/catalog.json',JSON.stringify(catalog)) ;

    const varFile = "webApps/slurmfrontend/resources/variables.json";
    grunt.log.writeln("=== Replace Variables in file " + varFile);
    var variables = JSON.parse(grunt.file.read(varFile));
    grunt.log.writeln("Old variables:"+JSON.stringify(variables,null,2));
    variables.user = grunt.config.get('variables.OCI_USER');
    variables.public_ip = grunt.config.get('variables.OCI_PUBLIC_IP');
    variables.secret_ocid = grunt.config.get('variables.OCI_SECRET_OCID');
    variables.path_conf_file = grunt.config.get('variables.OCI_PATH_CONF_FILE');
    variables.searchdate = grunt.config.get('variables.OCI_SEARCHDATE');

    grunt.log.writeln("New variables:"+JSON.stringify(variables,null,2));
    grunt.file.write(varFile,JSON.stringify(variables))

//    grunt.fail.warn("debug gvo")
  });
};
