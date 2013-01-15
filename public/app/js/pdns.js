"use strict";

var App = angular.module('pdns', ['pdnsServices', 'buttonsRadio', 'filters']).
    config(['$routeProvider', function($routeProvider) {
        $routeProvider.
            when('/domains', {templateUrl: 'views/domains.html',  controller: DomainsListCtrl}).
            when('/domain/:name', {templateUrl: 'views/domain-details.html', controller: DomainDetailsCtrl}).
            when('/domain/:name/:rid', {templateUrl: 'views/record.html', controller: RecordCtrl}).
            otherwise({redirectTo: '/domains'});
    }]);

angular.module('pdnsServices', []).
    factory('Domain', function($http) {
        var Domain = {
            query: function() {
                // $http returns a promise, which has a then function, which also returns a promise
                var promise = $http.get('/api/domain').then(function (response) {
                    // The then function here is an opportunity to modify the response
                    console.log(response);
                    // The return value gets picked up by the then in the controller.
                    return response.data.domains;
                });
                // Return the promise to the controller
                return promise;
            },
            get: function(name, cb) {
                var promise = $http.get('/api/domain/' + name).then(function (response) {
                    console.log(response);
                    if (cb) {
                        cb(response.data);
                    }
                    return response.data;
                });
                return promise;
            }
            // save:
            // records: ...
        };

        return Domain;
    }).
    factory('Record', function($rootScope, $http) {
        // var cache = {};
        // $rootScope.recordCache = cache;
        return function(record) {
            var Record = {
                $save: function(cb) {
                    var self = this;

                    // might make more sense to use _.pick() with an explicit list
                    var data = _.omit(self, _.functions(self));

                    var promise = $http.put(
                        '/api/record/' +
                            self.domain.name +
                            '/' + self.id,
                        {},
                        { params: self }
                    ).then(function (response) {
                        console.log("PUT RESPONSE", response);
                        if (cb) {
                            cb(response.data);
                        }
                        return response.data;
                    });
                    return promise;
                }
            };
            _.extend(Record, record);
            return Record;
        };
    });

angular.module('buttonsRadio', []).directive('buttonsRadio', function() {
    return {
        restrict: 'E',
        scope: { model: '=', options:'='},
        controller: function($scope){
            $scope.activate = function(option){
                $scope.model = option;
            };
        },
        template: "<button type='button' class='btn' "+
                    "ng-class='{active: option.v == model}'"+
                    "ng-repeat='option in options' "+
                    "ng-click='activate(option.v)'>{{option.l}} "+
                  "</button>"
    };
});

angular.module('filters', []).
        filter('dateFormat', function () {
            return function (ts) {
                console.log("TS", ts);
                return ts ? moment(ts).format("MMMM Do YYYY") : '';
            };
        });


