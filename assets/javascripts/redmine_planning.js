$.fn.copyCSS = function (source) {
    var dom = $(source).get(0);
    var dest = {};
    var style, prop;
    if (window.getComputedStyle) {
        var camelize = function (a, b) {
            return b.toUpperCase();
        };
        if (style = window.getComputedStyle(dom, null)) {
            var camel, val;
            if (style.length) {
                for (var i = 0, l = style.length; i < l; i++) {
                    prop = style[i];
                    camel = prop.replace(/\-([a-z])/, camelize);
                    val = style.getPropertyValue(prop);
                    dest[camel] = val;
                }
            } else {
                for (prop in style) {
                    camel = prop.replace(/\-([a-z])/, camelize);
                    val = style.getPropertyValue(prop) || style[prop];
                    dest[camel] = val;
                }
            }
            return this.css(dest);
        }
    }
    if (style = dom.currentStyle) {
        for (prop in style) {
            dest[prop] = style[prop];
        }
        return this.css(dest);
    }
    if (style = dom.style) {
        for (prop in style) {
            if (typeof style[prop] != 'function') {
                dest[prop] = style[prop];
            }
        }
    }
    return this.css(dest);
};