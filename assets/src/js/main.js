/* global $:false, Pikaday:false */

import 'bootstrap';
import 'chart.js';
import 'phoenix_html';
import 'popper.js';
import {
  config as faConfig,
  dom as faDom,
  library as faLibrary,
} from '@fortawesome/fontawesome-svg-core';
import {
  faChevronDown,
  faExternalLinkAlt,
  faLock,
  faQuestionCircle,
  faSignOutAlt,
} from '@fortawesome/free-solid-svg-icons';
import { faGithub } from '@fortawesome/free-brands-svg-icons';
import { throttle } from 'lodash-es';

import '../css/main.scss';

// Set up FontAwesome
faConfig.autoReplaceSvg = 'nest';
faLibrary.add(
  faChevronDown,
  faExternalLinkAlt,
  faLock,
  faQuestionCircle,
  faSignOutAlt,
  faGithub,
);

// For now, just assign these to the global scope to preserve existing code
window.$ = $;
window.Pikaday = Pikaday;
window.throttle = throttle;

// Trigger our various runtime effects on the browser DOM
$(() => {
  faDom.i2svg();
  $('[data-toggle="tooltip"]').tooltip();
});
