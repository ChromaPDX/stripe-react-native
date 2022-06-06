// hooks
export { useConfirmPayment } from './hooks/useConfirmPayment';
export { useConfirmSetupIntent } from './hooks/useConfirmSetupIntent';
export { useStripe } from './hooks/useStripe';
export { useApplePay, Props as UseApplePayProps } from './hooks/useApplePay';
export { useGooglePay } from './hooks/useGooglePay';

//components
export {
  initStripe,
  StripeProvider,
  Props as StripeProviderProps,
} from './components/StripeProvider';
export {
  ApplePayButton,
  Props as ApplePayButtonProps,
} from './components/ApplePayButton';
export {
  GooglePayButton,
  Props as GooglePayButtonProps,
} from './components/GooglePayButton';

export * from './functions';

export * from './types/index';
