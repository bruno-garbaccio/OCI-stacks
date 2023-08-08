define([
  'text!resources/variables.json'], function (
  varStrings) {
  'use strict';

  class PageModule {
  }

  PageModule.prototype.showRunningAndPending = function(array){
    var retArray = array.filter(function (row) {
      return row.state === "RUNNING" ||  row.state === "PENDING" ;
    });
    console.log(retArray)
    return retArray;
  }

  PageModule.prototype.parseFiles = function(files){
    var myFiles = []
    for (let i = 0; i < files.length; i++) {
      myFiles.push({"name" : files[i].name, "size" : files[i].size})
    }
    return myFiles;
  }

  PageModule.prototype.parseUploadedFile = function(fileSet){
      var readDataPromise = new Promise(function(resolve) {
      if (fileSet.length > 0) {
        //Grab the first (and only) file
        var csvFile = fileSet[0];
        //Check it's the correct type
        if (csvFile.type === 'text/csv') {
          //Create a File reader and its onload callback
          var fileReader = new FileReader();
          fileReader.onload = function(fileReadEvent) {
            var readCSVData = fileReadEvent.target.result;
            resolve(readCSVData);
          };
          fileReader.readAsText(csvFile);
        }
      }
    });
    console.log(readDataPromise);
    return readDataPromise;  
  }


  PageModule.prototype.convertbase64 = async function (data) {

    const blob = new Blob([data], {
      type: "application/octet-stream"
    });

    function blobToBase64(blob) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(blob);
        reader.onloadend = () => resolve(reader.result.toString().substr(reader.result.toString().indexOf(',') + 1));
        reader.onerror = error => reject(error);
      });
    };

    const retstring = await blobToBase64(blob);

    // console.log('retstring value', retstring);

    return retstring;
};

  PageModule.prototype.initVariables = async function () {
    const variables = JSON.parse(varStrings);
    return variables
  }

  
  return PageModule;
});
