import { config, dom, library } from '@fortawesome/fontawesome-svg-core';
import {
  faChartLine,
  faCheckSquare,
  faChevronDown,
  faCircle,
  faDownload,
  faExternalLinkAlt,
  faFilter,
  faInfoCircle,
  faLock,
  faMap,
  faPencilAlt,
  faQuestionCircle,
  faSignOutAlt,
  faSearch,
  faToggleOff,
  faToggleOn,
  faUndo,
} from '@fortawesome/free-solid-svg-icons';
import {
  faCalendarAlt,
  faSquare as faSquareO,
} from '@fortawesome/free-regular-svg-icons';
import { faGithub } from '@fortawesome/free-brands-svg-icons';

config.autoReplaceSvg = 'nest';
library.add(
  faCalendarAlt,
  faChartLine,
  faCheckSquare,
  faChevronDown,
  faCircle,
  faDownload,
  faExternalLinkAlt,
  faFilter,
  faInfoCircle,
  faLock,
  faMap,
  faPencilAlt,
  faQuestionCircle,
  faSearch,
  faSignOutAlt,
  faSquareO,
  faUndo,
  faGithub,
  faToggleOff,
  faToggleOn,
);

export default {
  config,
  dom,
  library,
};
