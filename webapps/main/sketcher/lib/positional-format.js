/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 László Monda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
if (!String.prototype.format) {

    String.prototype.format = function() {

        function toFixed(x) {

            var e;

            if (Math.abs(x) < 1.0) {

                e = parseInt(x.toString().split('e-')[1])

                if (e) {

                    x *= Math.pow(10, e - 1)
                    var pos = x.toString().indexOf('.') + 1,
                        pre = x.toString().substr(0, pos)

                    x = pre + (new Array(e + 1)).join('0') + x.toString().substring(pos)
                }

            } else {

                e = parseInt(x.toString().split('+')[1])

                if (e > 20) {

                    e -= 20
                    x /= Math.pow(10, e)
                    x += (new Array(e + 1)).join('0')

                }

            }

            return x

        }

        var args = arguments

        return this.replace(/{(\d+)}/g, function(match, number) {

            if (args[number] != 'undefined') {

                var arg = args[number],
                    isArgANumber = !isNaN(parseFloat(arg)) && isFinite(arg)

                return  isArgANumber ? toFixed(arg) : arg;

            } else {

                return match

            }

        })

    }

}
