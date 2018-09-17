/* global $:false, Pikaday:false */

import 'bootstrap';
import 'phoenix_html';
import 'popper.js';
import { throttle } from 'lodash-es';
import '../css/main.scss';
// This should just be covered by our config file. 
// https://github.com/webpack/webpack/issues/4258
import $ from 'jquery';  
import fontawesomeController from './fontawesome-controller';

// For now, just assign these to the global scope to preserve existing code
window.jQuery = $; window.$ = $;
window.Pikaday = Pikaday;
window.throttle = throttle;

// Trigger our various runtime effects on the browser DOM
$(() => {
  fontawesomeController.dom.i2svg();
  $('[data-toggle="tooltip"]').tooltip();
});
