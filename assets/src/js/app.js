/* global $:false, Pikaday:false */

/* general node_modules imports */
import 'popper.js';
import 'bootstrap';
import '@fortawesome/fontawesome-free/js/all';
import 'chart.js';
import 'phoenix_html';
import { throttle, debounce } from 'throttle-debounce';

/* Local imports */
// import socket from './socket';
import './map';

/* CSS imports (needed to force Webpack to bundle them) */
import '../css/app.scss';

// For now, just assign these to the global scope to preserve existing code
window.$ = $;
window.Pikaday = Pikaday;
window.throttle = throttle;
window.debounce = debounce;

// Tell FontAwesome to nest SVGs inside <i> tags, instead of replacing them
window.FontAwesome.config.autoReplaceSvg = 'nest';

// Tooltips are opt-in in Bootstrap 4, so we have to activate them
$(() => $('[data-toggle="tooltip"]').tooltip());
