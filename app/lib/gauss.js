var model = function (a, x) {
    var i, j, result = [], sig2 = a[1] * a[1], norm;
    norm = a[0] / Math.sqrt(2 * Math.PI * sig2);
    
    x = optimize.vector.atleast_1d(x);
    a = optimize.vector.atleast_1d(a);
    
    for (i = 0; i < x.length; i++) {
        var diff = x[i] - a[2];
        result.push(norm * Math.exp(-0.5 * diff * diff / sig2));
    }
    
    for (j = 3; j < a.length; j++) {
        for (i = 0; i < x.length; i++) {
            result[i] += a[j] * Math.pow(x[i], j - 3);
        }
    }
    
    return result;
};

var fit = function (data) {
    var data = $.extend(true, [], data);
    var xrange = d3.extent(data, function(d) { return d.x });
    var start = xrange[0]
    
    for(var i = 0; i < data.length; i++) {
      data[i].x -= start;
    }
    
    xrange[0] = 0
    
    var i, p0 = [-5, 0.1, 0.1, d3.median(data, function (d) { return d.y; })], p1, chi;
    var order = window.order || 3;
    
    for (i = 1; i <= order; i++) {
        p0.push(0.0);
    }
    
    chi = function (p) {
        var i, chi = [];
        if (Math.abs(p[1]) > (xrange[1] - xrange[0]) ||
                p[2] > xrange[1] || p[2] < xrange[0]) {
            for (i = 0; i < data.length; i++) {
                chi.push(1e10);
            }
        }
        for (i = 0; i < data.length; i++) {
            val = data[i].y - model(p, data[i].x)[0];
            chi.push(val);
        }
        
        return chi;
    };
    
    chi2 = function (p) {
        var c = chi(p);
        return optimize.vector.dot(c, c);
    };
    
    return optimize.newton(chi, p0);
};

module.exports = {
  model: model,
  fit: fit
}
