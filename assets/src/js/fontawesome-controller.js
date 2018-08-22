import { config, dom, library } from '@fortawesome/fontawesome-svg-core';
import {
  faChevronDown,
  faCircle,
  faExternalLinkAlt,
  faLock,
  faPencilAlt,
  faQuestionCircle,
  faSignOutAlt,
  faSearch,
  faUndo,
} from '@fortawesome/free-solid-svg-icons';
import { faCalendarAlt } from '@fortawesome/free-regular-svg-icons';
import { faGithub } from '@fortawesome/free-brands-svg-icons';

config.autoReplaceSvg = 'nest';
library.add(
  faCalendarAlt,
  faChevronDown,
  faCircle,
  faExternalLinkAlt,
  faLock,
  faPencilAlt,
  faQuestionCircle,
  faSearch,
  faSignOutAlt,
  faUndo,
  faGithub,
);

export default {
  config,
  dom,
  library,
};
