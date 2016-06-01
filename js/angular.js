var app= angular.module('myapp',['ui.router']);

app.config(['$stateProvider' , '$urlRouterProvider' ,'$locationProvider', function($stateProvider, $urlRouterProvider,$locationProvider) {
  $stateProvider
  .state('view', {
    url: '/project/:projectid/release-note/:releaseid/view',
    templateUrl: '/templates/release-notes-template.html',
    controller: 'releaseNoteController'
  })
  $urlRouterProvider.otherwise('/');
  $locationProvider.html5Mode({enabled: true,requireBase:false});
}]);

app.controller('releaseNoteController', ['$scope','$http','$stateParams', function($scope,$http,$stateParams){
  console.log("release note container to fetch db json");
  $scope.releaseid=$stateParams.releaseid;
  $http.get('fetch-release-note-json', {params:{"releaseid": $stateParams.releaseid}})
  .success(function(data, status) {
    $scope.release_note_json=data;
    $scope.section_data_json=$scope.release_note_json;
    console.log($scope.section_data_json);
  });

  $scope.downloadReleaseNotes=function() {
    console.log("gb");
    var notesName = document.getElementById('release-notes-name').innerHTML;
    var mainContent = document.getElementById('main-content').innerHTML;
    var link = document.createElement('a');
    link.setAttribute('download', "release_notes.html");
    link.setAttribute('href', 'data:' + 'text/html'  +  ';charset=utf-8,' +encodeURIComponent("<h2>"+notesName+"</h2>")+ encodeURIComponent(mainContent));
    link.click(); 
  }
}]);

// to add section 
app.directive("sectionDirective", function () {
  return {
    restrict: 'A', 
    replace: true,
    scope: {
      section_data_json: "=json",
    },
    templateUrl: '/templates/section-data-template.html'
  }
});


app.controller('sectioncontroller', ['$scope', '$http', function($scope,$http){

  $scope.insertSection=function() {
    console.log($scope.title);
    if($scope.title != null)
    {
      $http.get('main-content-json?releaseid='+$scope.releaseid+'&title='+$scope.title)
      .success(function(data, status) {
        $scope.section_data_json=data;
        console.log("section json ======>" , $scope.section_data_json);
      })
    }
  }

  $scope.deleteSection=function(delete_section_id) {
    console.log("delete_section_id===> ",delete_section_id);
    $http.get('main-content-json?releaseid='+$scope.releaseid+'&delete_section='+delete_section_id)
    .success(function(data, status) {
      $scope.section_data_json=data;
      console.log("section json ======>" , $scope.section_data_json);
    })
  }
  

  $scope.insertContent=function(info){
    console.log("insertContent");
    console.log(info.newtitle);
    console.log(info.description);
    console.log(info.contentid);
    console.log(info.sectionid);
    info.newtitle = info.newtitle.replace(/\#/g, '+');
    console.log(info.newtitle);
    if (info.description == undefined){
      info.description="";
    }
    $http.get('main-content-json?releaseid='+$scope.releaseid+'&contentid='+info.contentid+'&sectionid='+info.sectionid+'&description='+info.description+'&newtitle='+info.newtitle)
      .success(function(data, status) {
        console.log("data123 ======>" , data);
        $scope.section_data_json=data;
        console.log("section json ======>" , $scope.section_data_json);
      })
  }

  $scope.deleteSectionContent=function(delete_content_id){
    console.log("delete_content_id===> ",delete_content_id);
    $http.get('main-content-json?releaseid='+$scope.releaseid+'&delete_section_content='+delete_content_id)
    .success(function(data, status) {
      $scope.section_data_json=data;
      console.log("section json ======>" , $scope.section_data_json);
    })
  }

$scope.dropContent = function () {
    console.log("drop event");
  }
}]);

// =====> to cut and uncut content from all content section RHS
app.controller('contentcontroller', ['$scope', '$http', function($scope,$http){
  $scope.deleteRestoreContent=function(element) {
    console.log(element.target.parentNode.id);
    console.log("as");
    var li_tag=element.target.parentNode;
    var content_id=li_tag.id;
    
    $http.get('check-content?content-id='+content_id)
    .success(function(data, status) {
      $scope.isDeleted=data;
      //console.log($scope.isDeleted);
      if ($scope.isDeleted != 'T')
        {
          $(element.target).parent().find("#drag-id").attr("style","pointer-events:none");
          $(element.target).next().attr("style","display:none");
          $(element.target).attr("class","fa fa-undo content-list-undo");
          $(element.target).attr("style","color:green");
          $http.get('cut-content?content-id='+content_id)
          .success(function(data, status) {
            console.log("cut");

            li_tag.setAttribute('style','text-decoration:line-through;color: #C1BDBD;');
          })
        }
        else
        {
          $(element.target).parent().find("#drag-id").attr("style","pointer-events:all");
          $(element.target).next().attr("style","display:block");
          $(element.target).attr("class","fa fa-trash-o content-list-delete");
          $(element.target).attr("style","color:red");
          $http.get('uncut-content?content-id='+content_id)
          .success(function(data, status) {
            console.log("uncut");
            li_tag.setAttribute('style','text-decoration:none;color:black');
          })
        }
      });
  }
}]);

// =====> drag directive
app.directive('dragContent', ['$timeout', function($timeout){
  return {
    restrict: 'A',   
    replace: true,
    link: function($scope, $elem, $attr) {
      //console.log("$elem", $elem.parent());
      $elem.draggable({
        helper: "clone",
        revert: 'invalid',
        appendTo: "body",
        zIndex: 100,
        drag: function (event, ui) {
          $(ui.helper).html($(this).parent()[0].innerHTML);
          //console.log($(ui.helper)[0]);
          //$(ui.helper).find('span').remove();
          $(ui.helper).css("color", "blue");
          $(ui.helper).css("font-size", "20px");     
        }
      })
    }
  }
}]);


// =====> drop directive
app.directive("dropContent", function ($compile) {

  return {
    restrict: 'A', 
    replace: false,
    scope: {
      action: "&",
      sectionarray: "="
    },
    
    link: function(scope, $elem, $attr) {
      scope.isdrop=false;
      $elem.droppable({
      accept: ".drag"
      });
      
      $elem.bind("drop", function(ent,ui) {
        //console.log("var",scope.action());
        droppedElem = ui.draggable;

        scope.message=$(droppedElem.parent()[0]).find('#content-message')[0].innerHTML;
        scope.section_id=$elem[0].id;
        scope.content_id=$(droppedElem.parent()[0])[0].id;
        //scope.action();
        console.log("old",scope.isdrop);
        scope.isdrop=true;
        // console.log("new",scope.isdrop);
        // console.log(scope.action);
        // console.log(scope.message);
        // console.log(scope.section_id);
        // console.log(scope.content_id);
        // console.log(scope.droppedElem);
        //scope.message='"'+scope.message+'"';

        var template = "<li style=\"margin-left:-19px;\">"+
                        "<form ng-submit=\"action({newtitle: newtitle,description: description,contentid: contentid,sectionid: sectionid})\" >"+
                        "<input type=\"hidden\" name=\"contentid\" ng-model='contentid' ng-init=\"contentid='"+scope.content_id+"'\" >"+
                        "<input type=\"hidden\" name=\"sectionid\" ng-model='sectionid' ng-init=\"sectionid='"+scope.section_id+"'\" >"+
                        
                        "<input type=\"text\" style=\"width:97%\" name=\"message\" ng-model='newtitle' ng-init=\"newtitle='"+scope.message+"'\" required><br>"+
                        "--<input type=\"text\" style=\"width:80%\" name=\"description\" placeholder=\"description\" ng-model=\"description\">"+
                        "<input type=\"submit\" class=\"btn btn-primary\" id=\"submit\" value=\"Save\" />"+
                        "</form>"+
                       "</li>";
        
       $elem.append($compile(template)(scope));
      });
      //console.log("dis=",scope.isdrop);
    },
    /*
    template: '<li style="margin-left:-19px;font-weight: bold;" ng-if="sectionarray[0].length !=0 " ng-repeat="section_data in sectionarray">'+
                '<span>{{section_data.title}}</span>'+
                '<span style="margin-left:8px;" class="label label-success">on {{ (section_data.date*1000) - 2209008600000 | date: \'MMM d, y\'}}</span>'+
                '<br>'+
                '<span style="color:grey" ng-if="section_data.description">-- {{section_data.description}}</span>'+
              '</li>'+
              '<li style=\"margin-left:-19px;\" ng-if="isdrop">'+
                '<input type=\"text\" name=\"message\" value=scope.message>'+
                '--<input type="text" name="description" placeholder="description"/>'+
                '<div class="btn btn-primary" ng-click="action()">Save</div>'+
              '</li>'
    */

  }
});


// =====> directive for the li content
app.directive("contentDirective", function () {
  return {
    restrict: 'A',
    replace: true,
    scope: {
      accordian: "@",
      json: "=",
      type: "@",
      deletemethod: '&'
    },
    templateUrl: '/templates/content-list-template.html'
  }
});

// =====> directive to show extra details of the content
app.directive("showExtraDirective", function () {
  return {
    restrict: 'A',
    replace: true,
    scope: {
      type: '@',
      content: "=",
    },
    link: function(scope, element, attrs) {
      scope.templateName = '/templates/extra-' + scope.type + '-template.html';
    },
    template: '<div ng-include="templateName"></div>'
  }
});
