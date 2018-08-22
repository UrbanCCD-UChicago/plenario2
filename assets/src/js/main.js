/* global $:false, Pikaday:false */

import 'bootstrap';
import 'phoenix_html';
import 'popper.js';
import { throttle } from 'lodash-es';
import '../css/main.scss';
import fontawesomeController from './fontawesome-controller';

// For now, just assign these to the global scope to preserve existing code
window.$ = $;
window.Pikaday = Pikaday;
window.throttle = throttle;

// Trigger our various runtime effects on the browser DOM
$(() => {
  fontawesomeController.dom.i2svg();
  $('[data-toggle="tooltip"]').tooltip();
});
