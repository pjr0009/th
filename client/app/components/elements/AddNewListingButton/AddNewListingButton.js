import { PropTypes } from 'react';
import { a, span } from 'r-dom';
import classNames from 'classnames';

import { className as classNameProp } from '../../../utils/PropTypes';

import * as variables from '../../../assets/styles/variables';
import css from './AddNewListingButton.css';

export default function AddNewListingButton({ text, url, customColor, className, mobileLayoutOnly }) {
  const buttonText = `+ ${text}`;
  const color = customColor || variables['--AddNewListingButton_defaultColor'];
  return a({
    className: classNames(className, 'AddNewListingButton', css.button, { [css.responsiveLayout]: !mobileLayoutOnly }),
    href: url,
    title: text,
  }, [

    // Since we have to inline the marketplace color as the background
    // of this button (or text color on mobile), and the :hover styles
    // change the brightness of the dynamic background color, we have
    // to create a separate background container to avoid changing the
    // brightness of the text on top of the button.
    span({
      className: 'AddNewListingButton_background',
      classSet: { [css.backgroundContainer]: true },
      style: { backgroundColor: color },
    }),

    span({
      className: 'AddNewListingButton_mobile',
      classSet: { [css.mobile]: true },
      style: { color },
    }, buttonText),
    span({
      className: 'AddNewListingButton_desktop',
      classSet: { [css.desktop]: true },
    }, buttonText),
  ]);
}

AddNewListingButton.propTypes = {
  text: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  mobileLayoutOnly: PropTypes.bool,

  // Marketplace color or default color
  customColor: PropTypes.string,
  className: classNameProp,
};
