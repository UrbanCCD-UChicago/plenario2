/* global $:false, Pikaday:false */

/* node_modules imports */
import 'popper.js';
import 'bootstrap';
import 'phoenix_html';

/* Local imports */
// import socket from './socket';
import './map';

/* CSS imports (needed to force Webpack to bundle them) */
import '../css/app.scss';

// For now, just assign these to the global scope to preserve existing code
window.$ = $;
window.Pikaday = Pikaday;