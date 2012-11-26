'use strict';

function DomainsListCtrl($scope, Domain) {
    $scope.domains = Domain.query();
    console.log("DOMAINS", $scope.domains);
    // $scope.orderProp = 'date';
}

function _setup_records(data, $scope, $rootScope) {
    $scope.domain  = data.domain;
    $scope.records = data.records;
    $rootScope.records = {};
    _.each(data.records, function(r) {
        r.domain = { name: data.domain.name };
        $rootScope.records[r.id] = r;
    });
}

function DomainDetailsCtrl($scope, $rootScope, $routeParams, Domain, Record) {
    var self = this;
    console.log("domain details", $routeParams);
    Domain.get($routeParams.name, function(data) {
        _setup_records(data, $scope, $rootScope);
        console.log("got domain", $scope.domain, $rootScope.records);
    });

    $scope.set_cache = function(id) {
        console.log("setting cache", id, $scope.records);
        var r = $rootScope.records[id];
        console.log("Found R", r);
    };

}

function RecordCtrl($scope, $rootScope, $routeParams, Domain, Record) {
    var self = this;
    var rId = $routeParams.rid;
    console.log("RootSCope", $rootScope);
    if ($rootScope.records && $rootScope.records[rId]) {
        self.original = $rootScope.records[rId];
        $scope.record = new Record(self.original);
    }
    else {
        Domain.get($routeParams.name, function(data) {
            _setup_records(data, $scope, $rootScope);
            self.original = $rootScope.records[rId];
            $scope.record = new Record(self.original);
            console.log("got domain - recordsctrl", $scope.domain, $rootScope.records);
        });
    }

    console.log("going to show", rId, $scope.record);

    $scope.isClean = function() {
        var clean = angular.equals(self.original, $scope.record);
        console.log("Clean:", clean, self.original, $scope.record, $scope.foo);
        return clean;
    };

    $scope.saveState = function() {
        var clean = $scope.isClean();
        if (clean) {
            return 'Saved';
        }
        else {
            return 'Save';
        }
    };

    $scope.save = function() {
        console.log("SAVING!");
        $scope.foo = $scope.record.$save();
    };
}