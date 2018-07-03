/* global $:false, Pikaday:false */

/* general node_modules imports */
import 'popper.js';
import 'bootstrap';

import 'chart.js';
import 'phoenix_html';

/* Font Awesome Icons */
import { library } from '@fortawesome/fontawesome-free/js/fontawesome';
import { lock } from '@fortawesome/fontawesome-free/js/solid';
import { github } from '@fortawesome/fontawesome-free/js/brands';

/* Local imports */
// import socket from './socket';
import './map';

/* CSS imports (needed to force Webpack to bundle them) */
import '../css/app.scss';

/* Register FontAwesome icons to the library */
library.add(
  lock,
  github,
);

// For now, just assign these to the global scope to preserve existing code
window.$ = $;
window.Pikaday = Pikaday;
