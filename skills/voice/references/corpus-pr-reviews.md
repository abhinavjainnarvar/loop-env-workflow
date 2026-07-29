===== SECTION A: comments on OTHER PEOPLE PRs (human-likely) =====
[HUMAN-LIKELY] shopify-zero-retailer#2186 (PR author: killalau) | 2024-11-07 | kind=review-body
Looks good

[HUMAN-LIKELY] shopify-zero-retailer#2189 (PR author: killalau) | 2024-11-11 | kind=review-comment | app/javascript/retailer-app/pages/Onboarding/Onboarding.js:71
Can we remove the property `exact` as it has been deprecated and all the routes are exact by default?

[HUMAN-LIKELY] shopify-zero-retailer#2189 (PR author: killalau) | 2024-11-11 | kind=pr-comment
Looks good to me in terms of the upgrade.

[HUMAN-LIKELY] shopify-zero-retailer#2241 (PR author: killalau) | 2024-12-03 | kind=review-comment | package.json:171
Thanks for fixing this. We finally got rid of it!

[HUMAN-LIKELY] shopify-zero-retailer#2248 (PR author: prathameshVic) | 2024-12-04 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:None
We can keep the default value in the function argument as this statement is same as `draft.isUat`. For eg: True || false, False || false
```suggestion
    draft.isUat,
```

[HUMAN-LIKELY] shopify-zero-retailer#2248 (PR author: prathameshVic) | 2024-12-04 | kind=review-comment | app/javascript/retailer-app/data/capriCarrierService.js:None
```suggestion
export function useCapriCredentialsSchema(moniker, isUat = false) {
```

[HUMAN-LIKELY] shopify-zero-retailer#2248 (PR author: prathameshVic) | 2024-12-04 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:None
If `uatSupported` is a boolean, then we can write prepend with `!!` as they will convert any falsy value(`undefined`, `null`) to a boolean while keeping the same value if its a boolean.

```suggestion
  const uatSupported =
    !!capriCarriers?.data?.availableCarrierServices?.find(c => {
      return c.carrierMoniker === moniker;
    })?.uatSupported;
```

[HUMAN-LIKELY] shopify-zero-retailer#2248 (PR author: prathameshVic) | 2024-12-04 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:None
```suggestion
              checked={draft.isUat}
```

[HUMAN-LIKELY] shopify-zero-retailer#2248 (PR author: prathameshVic) | 2024-12-04 | kind=review-body
Looks good on Javascript side. I have added some minor improvements.

[HUMAN-LIKELY] shopify-zero-retailer#2312 (PR author: killalau) | 2025-01-07 | kind=review-comment | app/javascript/retailer-app/data/apollo-cache.js:None
Can we rewrite this logic to improve readability? We can have if else and store function in a variable like
```
if(overwriteCache) func = updated
else if(deleteCache)
.....
```

[HUMAN-LIKELY] shopify-zero-retailer#2320 (PR author: killalau) | 2025-01-12 | kind=review-body
Looks good to me!

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-22 | kind=review-comment | lib/shopify_zero/deploy/app.rb:None
I had pushed a commit to remove this. It was probably around the same time you reviewed. Good catch!

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-23 | kind=review-comment | app/javascript/shop-now/data.js:183
`.json` is a Promise function and the value can only be resolved once. `.then` is used for promises. In the code, first `.then` resolves the first promise `res.json()` and then the next `.then` is executed. Let me know if this makes sense.

This can also be written like this. 
```
.then(async(res) => {
      let res = await res.json();
      // fatal error case is handle by its caller `onSubmit()`
      if (res.status === "invalid" || !res.weburl) {
        throw new Error(res?.message || JSON.stringify(res));
	@@ -191,7 +191,7 @@ export const submitCheckout = ({ items, code }) =>
      return res;
    });
```

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useDiscountCode.ts:None
`checkoutDataResult.loading` is not set to loading when we call `refetchCheckoutData` as I didn't enable the option `notifyOnNetworkStatusChange` with Apollo which allows that. This is done intentionally as the loading will cause the entire page to show loading which would not be right.

For this reason, I have a separate state to track the loading. I feel `checkoutData` should not be a part of this hook and it can be eliminated by accepting a `successCallback` instead of `refetchCheckoutData`.
I'll make the change.

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/usePayment.ts:6
Types and interfaces can be used interchangeably in most of the scenarios without any concerns but they have some differences. This is from the official documentation:

> Unlike an interface declaration, which always introduces a named object type, a type alias declaration can introduce a name for any kind of type, including primitive, union, and intersection types.

We can create ground rules on what we prefer for a project. I prefer using interfaces while defining objects with **key-value** properties, extend and add more **key-value** properties and some other basic interface functionalities.

I use Types to play around with the interfaces or primitive types where you are not defining an object and its properties. Types provide you with some functionalities which are really useful like it will let you extract a new type from interfaces. It will also allow you to merge types/interfaces and let you omit some keys from an interface and provide a name to it. For primitives, it lets you have enum types. Basically anything without the object(**key-value**) interface in Typescript, I would use a type for its capabilities.
For example, this is what we saw in the demo yesterday:
```
// We are defining **key value** fields
interface Metrics {
   visits: number;
   sales: number;
   conversion_rate: number;
}

// We are extending and defining new **key value** fields
interface ExtendedMetrics extends Metrics {
   revenue: number;
}

In the above examples, I prefer using interface but type can be used as well

//Zod schema
const MetricsSchema = z.object({
  visits: z.number(),
  sales: z.number(),
  revenue: z.number(),
  conversion_rate: z.number(),
});

//We have to use type as we are creating a name for a new type returned here. Not possible with interfaces with my understanding
type MetricsSchema = z.infer<typeof MetricsZod>

// Not possible to do it using interfaces
type refundMethod = "original_payment" | "gift_card";

// Possible to do with it interfaces but I find this more precise
type applyDiscountCode = (code: string) => Promise<void>

//Not possible to do it with interfaces
// type ShortMetrics = Pick<MetricsSchema, "visits", "sales">;

```

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useSubmit.ts:None
This is a good suggestion. I generally hate putting try and catch maybe thats why there is a bias. This one looks neat too.

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/consumer-app/components/App.js:None
No, we can remove some of the unwanted stuff. I think it did not highlight because of Javascript.

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/consumer-app/components/AppRouter.js:41
Yeah, it is copied from the above file:
app/javascript/consumer-app/components/App.js

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | app/javascript/shop-now/data.js:205
I tried to disable it but for some reason it did not help. The changes are only reflected in the file I made changes so I felt it was fine. It would be nice to not have these changes.

[HUMAN-LIKELY] shopify-zero-retailer#2286 (PR author: jeetnarvar) | 2025-01-24 | kind=review-comment | package.json:None
Nice catch!

[HUMAN-LIKELY] shopify-zero-retailer#2383 (PR author: prathameshVic) | 2025-02-04 | kind=review-comment | app/javascript/retailer-app/components/rules/utils.js:None
Are we missing any condition here? If not, we can combine the 2 ifs

[HUMAN-LIKELY] shopify-zero-retailer#2383 (PR author: prathameshVic) | 2025-02-04 | kind=review-comment | app/javascript/retailer-app/data/refundMethodRules.js:None
I saw this done above as well but we don't really need to memoize this. There is no computation required here. We can directly derive the value.
```
const shopifyReturnApiFfEnabled = saved.data
    ? saved.data.shopifyReturnApiPreferences.value
    : false;
```

[HUMAN-LIKELY] shopify-zero-retailer#2383 (PR author: prathameshVic) | 2025-02-04 | kind=review-comment | app/javascript/retailer-app/pages/RefundMethodRuleForm/RefundMethodRuleForm.js:None
Just something I do to make things consistent. Considering `shopifyReturnApiFfEnabled` is a boolean, I would initialize it to false instead of undefined.
```
const {
    state: { rule, shopifyReturnApiFfEnabled } = {
      shopifyReturnApiFfEnabled: false,
    },
```

[HUMAN-LIKELY] shopify-zero-retailer#2404 (PR author: narvarjdibella) | 2025-02-18 | kind=review-comment | app/javascript/retailer-app/data/issue.js:None
nit: We can use `window.localStorage` as we are calling using the same on the other places. They are the same thing.

[HUMAN-LIKELY] shopify-zero-retailer#2404 (PR author: narvarjdibella) | 2025-02-18 | kind=review-comment | app/javascript/retailer-app/pages/IssueDetails/IssueDetails.js:None
What does it show when updatedAt is not present?

[HUMAN-LIKELY] shopify-zero-retailer#2421 (PR author: killalau) | 2025-02-26 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/components/ItemCard/ItemCard.tsx:82
Just making sure this change is intentional and tested

[HUMAN-LIKELY] shopify-zero-retailer#2421 (PR author: killalau) | 2025-02-26 | kind=review-comment | app/javascript/consumer-app/modules/items.js:None
Could these functions be outside the hook?

[HUMAN-LIKELY] shopify-zero-retailer#2438 (PR author: jeetnarvar) | 2025-03-05 | kind=review-comment | app/javascript/retailer-app/pages/General/General.js:None
I am trying to see if need the hook here. Maybe we can discuss after the standup

[HUMAN-LIKELY] shopify-zero-retailer#2438 (PR author: jeetnarvar) | 2025-03-10 | kind=review-comment | app/javascript/retailer-app/pages/General/General.js:None
Can we try something like this instead of effect? Feel free to modify the return value of `exportSaleAdjustmentReport`. Doing this to make easier to read and avoid side effects(if it is unnecessary).
```
const handleDownloadAdjustmentReport = useCallback(async () => {
    try {
      const { data } = await exportSaleAdjustmentReport({
        startTime: dateRange.startTime,
        endTime: dateRange.endTime,
      });
      if (data.exportSaleAdjustmentReport) {
        const csvString = atob(data.exportSaleAdjustmentReport);
        const blob = new Blob([csvString], { type: "text/csv" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.setAttribute("download", "sale_adjustment_report.csv");
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
    } catch (error) {
      console.error(error);
    }
  });
```

[HUMAN-LIKELY] shopify-zero-retailer#2544 (PR author: killalau) | 2025-04-02 | kind=review-comment | app/javascript/consumer-app/contexts/nthContext.js:575
I liked using claim as opposed to returns. It was clear we are talking about claims. I was not able to connect return claim.

[HUMAN-LIKELY] shopify-zero-retailer#2544 (PR author: killalau) | 2025-04-02 | kind=review-comment | app/javascript/consumer-app/steps/Confirmation/Confirmation.js:189
nit: We could use useCallback

[HUMAN-LIKELY] shopify-zero-retailer#2544 (PR author: killalau) | 2025-04-03 | kind=review-comment | app/javascript/consumer-app/steps/Confirmation/Confirmation.js:189
It was not required in the previous implementation as no new memory was allocated for creating a function. Operation is very light. It was just for new memory allocation.

[HUMAN-LIKELY] shopify-zero-retailer#2560 (PR author: killalau) | 2025-04-04 | kind=pr-comment
@killalau Can we add changes to `ReturnReasons/types.ts`
```
isClaim?: boolean;
```

[HUMAN-LIKELY] shopify-zero-retailer#2578 (PR author: killalau) | 2025-04-11 | kind=review-comment | app/javascript/shop-now/fancybannerStyles.js:81
Couldn't find this variable declared: `--narvar-option-line-height`

[HUMAN-LIKELY] shopify-zero-retailer#2578 (PR author: killalau) | 2025-04-11 | kind=review-comment | app/javascript/shop-now/fancybannerStyles.js:130
@killalau Any reason to move out of rem?

[HUMAN-LIKELY] shopify-zero-retailer#2578 (PR author: killalau) | 2025-04-11 | kind=review-comment | app/javascript/shop-now/fancybannerStyles.js:135
Is this duplicate line as below?

[HUMAN-LIKELY] shopify-zero-retailer#2578 (PR author: killalau) | 2025-04-11 | kind=review-comment | app/javascript/shop-now/fancybannerStyles.js:138
duplicate?

[HUMAN-LIKELY] shopify-zero-retailer#2594 (PR author: killalau) | 2025-04-16 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:9
Thanks for catching these @killalau

[HUMAN-LIKELY] shopify-zero-retailer#2493 (PR author: jeetnarvar) | 2025-04-22 | kind=review-comment | app/javascript/consumer-app/config.js:305
@jeetnarvar This needs to be added to `loadHyper` call right?

[HUMAN-LIKELY] shopify-zero-retailer#2493 (PR author: jeetnarvar) | 2025-04-25 | kind=review-comment | app/javascript/consumer-app/checkout/components/CheckoutForm.tsx:25
Unable to receive this from backend. Please look into this @jeetnarvar

[HUMAN-LIKELY] shopify-zero-retailer#2677 (PR author: killalau) | 2025-05-06 | kind=review-body
@killalau You can look at the suggestion of copilot but looks good to me.

[HUMAN-LIKELY] shopify-zero-retailer#2647 (PR author: killalau) | 2025-05-08 | kind=review-comment | app/javascript/consumer-app/ItemSelector/helper.tsx:566
Nice refactor

[HUMAN-LIKELY] shopify-zero-retailer#2647 (PR author: killalau) | 2025-05-08 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/components/LineItemsGroup/index.tsx:65
Can we look into putting this into another component or optimize re renders for better performance?

[HUMAN-LIKELY] shopify-zero-retailer#2647 (PR author: killalau) | 2025-05-08 | kind=review-comment | app/javascript/consumer-app/steps/ChooseItems/ChooseItems.js:None
Will it make sense to memoize this? nit: We could create a separate hook now or later to reduce the complexity on this component.

[HUMAN-LIKELY] shopify-zero-retailer#2647 (PR author: killalau) | 2025-05-08 | kind=review-comment | app/javascript/consumer-app/steps/ChooseItems/ChooseItems.js:575
Similar comment

[HUMAN-LIKELY] shopify-zero-retailer#2657 (PR author: jeetnarvar) | 2025-05-12 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useCheckout.tsx:None
nit: We can rewrite this as `!!data?.payment?.paymentClientSecret`

[HUMAN-LIKELY] shopify-zero-retailer#2657 (PR author: jeetnarvar) | 2025-05-12 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:None
We can clear the log

[HUMAN-LIKELY] shopify-zero-retailer#2657 (PR author: jeetnarvar) | 2025-05-12 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:None
Do we need `isCharge` now?

[HUMAN-LIKELY] shopify-zero-retailer#2657 (PR author: jeetnarvar) | 2025-05-12 | kind=pr-comment
Do we need to make any changes on Checkout.tsx too? The PR only focuses on normal exchanges flow.

[HUMAN-LIKELY] shopify-zero-retailer#2657 (PR author: jeetnarvar) | 2025-05-14 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useCheckout.tsx:None
@jeetnarvar Notes: We discussed to update this to include additional field `paymentChargeable` or something similar.

[HUMAN-LIKELY] shopify-zero-retailer#2714 (PR author: jeetnarvar) | 2025-05-22 | kind=review-body
Looks good to me too. Should we clean up METHOD_XPO in `constants/returns.js` if it is not used anywhere.

[HUMAN-LIKELY] shopify-zero-retailer#2739 (PR author: killalau) | 2025-05-29 | kind=review-body
Great work. Looks good to me. nit: I prefer having one file for the language. It can create different constants for rma, common and dashboard but would keep all the translations in one file. Only slight difference from the current approach so we should be good to go!

[HUMAN-LIKELY] shopify-zero-retailer#2794 (PR author: killalau) | 2025-06-19 | kind=review-comment | extensions/narvar-pos-returns/gql/graphql.ts:62
I've added a codegen documentation: https://github.com/narvar/shopify-zero-retailer/blob/develop/doc/dev/frontend/codegen.md. I am merging it for now. We can add it later.

[HUMAN-LIKELY] shopify-zero-retailer#2797 (PR author: narvarjdibella) | 2025-06-19 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:None
@narvarjdibella Minor improvement here. We don't need to write this logic in useEffect as there is no side effect. We are just updating a variable with the latest error info. We can simply create a variable outside and use it for showing errorCodes. I'n going to write a sample code which we can add it in `useCheckout.ts` to keep it all clean.

```jsx
const getCheckoutErrorMessageForErrorCode = (code: string | undefined) => {
  if (!code) return "";
  switch (code) {
    case "Z506":
      return interpolate(
        getTranslation("shop_now_checkout_cart_products_unavailable"),
        {
          errorCode: code,
        },
      );
    default:
      return "An unknown error occurred. Please try again.";
  }
};

const checkoutInfo = useMemo(() => {
    const data = checkoutResponse?.shopNowV2Checkout.data;
    const checkoutErrorCode =
      checkoutResponse?.shopNowV2Checkout.errors[0]?.code;
    return {
      checkoutData: data,
      paymentClientSecret: data?.payment?.paymentClientSecret ?? "",
      paymentRequired: !!data?.payment?.isChargeable,
      discountCodeSaved: data?.overallCartSummary.discountCodes?.[0],
      paymentProcessorPubKey: data?.payment?.paymentProcessorPubKey ?? "",
      paymentNarvarRefId: data?.payment?.paymentRef ?? "",
      paymentProvider: data?.payment?.paymentProvider ?? "",
      paymentProcessorId: data?.payment?.paymentProcessorId ?? "",
      checkoutErrorCode,
      checkoutErrorMessage:
        getCheckoutErrorMessageForErrorCode(checkoutErrorCode),
    };
  }, [checkoutResponse]);
```

We can use the variables in Checkout.tsx component to render the error message.

[HUMAN-LIKELY] shopify-zero-retailer#2797 (PR author: narvarjdibella) | 2025-06-19 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/__tests__/useCheckout.spec.js:None
Thanks for the test cases 🙏
nit: The extension can be `.ts` instead of `.js` to be consistent with the other test cases and to catch any potential type errors.

[HUMAN-LIKELY] shopify-zero-retailer#2800 (PR author: killalau) | 2025-06-23 | kind=review-comment | extensions/narvar-pos-returns/src/utils/returnUi.ts:1
Can we change the name of the file to something more explicit?
Like `returnStates` or even `getStatesColor.ts`

[HUMAN-LIKELY] shopify-zero-retailer#2800 (PR author: killalau) | 2025-06-23 | kind=review-comment | extensions/narvar-pos-returns/src/screens/ReturnSearch.tsx:24
@killalau Is `useCallback` unnecessary here? The debounced function might already be memoized and it will not make much difference

[HUMAN-LIKELY] shopify-zero-retailer#2800 (PR author: killalau) | 2025-06-24 | kind=review-comment | extensions/narvar-pos-returns/src/utils/returnUi.ts:1
Sure. Lets do that for now.

[HUMAN-LIKELY] shopify-zero-retailer#2800 (PR author: killalau) | 2025-06-24 | kind=review-comment | extensions/narvar-pos-returns/src/screens/ReturnSearch.tsx:24
Thanks for the clarification right. Yes, debounce creates a new function every time so good to use the callback hook here.

[HUMAN-LIKELY] shopify-zero-retailer#2800 (PR author: killalau) | 2025-06-24 | kind=review-comment | extensions/narvar-pos-returns/src/data/useEditReturn.ts:2
👍

[HUMAN-LIKELY] shopify-zero-retailer#2812 (PR author: killalau) | 2025-06-26 | kind=review-comment | extensions/narvar-pos-returns/src/hooks/useMemoObject.ts:3
Nice abstraction

[HUMAN-LIKELY] shopify-zero-retailer#2839 (PR author: killalau) | 2025-07-07 | kind=review-comment | extensions/narvar-pos-returns/src/screens/ReturnScanner.tsx:23
Do we need the scanEventId?

[HUMAN-LIKELY] shopify-zero-retailer#2844 (PR author: killalau) | 2025-07-08 | kind=review-body
Frontend changes look good

[HUMAN-LIKELY] shopify-zero-retailer#2914 (PR author: killalau) | 2025-07-29 | kind=review-body
Not sure how this created the issue but lets deploy and check.

[HUMAN-LIKELY] shopify-zero-retailer#2920 (PR author: killalau) | 2025-08-01 | kind=review-comment | app/javascript/consumer-app/components/type-form/TypeFormController.js:4
Nice 👍

[HUMAN-LIKELY] shopify-zero-retailer#2920 (PR author: killalau) | 2025-08-01 | kind=review-comment | app/javascript/consumer-app/components/type-form/TypeFormController.js:18
Do we need this field `immediateScroll`? Also, we don't need PropTypes anymore. We can just convert this file into `.ts`. 

Update: Looks like the field is used by the parent and you added the comment too.

[HUMAN-LIKELY] shopify-zero-retailer#2920 (PR author: killalau) | 2025-08-01 | kind=review-comment | app/javascript/consumer-app/components/type-form/TypeForm.js:38
This is an interesting pattern. Should the functionality be with the `TypeFormController` component?

[HUMAN-LIKELY] shopify-zero-retailer#2920 (PR author: killalau) | 2025-08-01 | kind=review-body
Result looks fine. Minor comments added

[HUMAN-LIKELY] shopify-zero-retailer#2939 (PR author: narvarjdibella) | 2025-08-06 | kind=review-comment | app/views/home/admin_create_return.html.erb:6
Nice 👍

[HUMAN-LIKELY] shopify-zero-retailer#2927 (PR author: narvarjdibella) | 2025-08-11 | kind=review-comment | app/javascript/consumer-app/steps/OrderLookup/OrderLookupLogin.js:None
See if there is a theme color red available to use here.

[HUMAN-LIKELY] shopify-zero-retailer#2927 (PR author: narvarjdibella) | 2025-08-11 | kind=review-comment | app/javascript/consumer-app/steps/OrderLookup/OrderLookupLogin.js:None
Move inline styles to classes

[HUMAN-LIKELY] shopify-zero-retailer#2927 (PR author: narvarjdibella) | 2025-08-11 | kind=review-comment | app/javascript/consumer-app/steps/OrderLookup/OrderLookupLogin.js:None
Combining conditions into variables to increase readability

[HUMAN-LIKELY] shopify-zero-retailer#2927 (PR author: narvarjdibella) | 2025-08-11 | kind=review-comment | app/javascript/shared/components/Spinner.js:31
Can you just check how the class is rendered when className is empty?
Suggestion
```
[className]: !!className
```

[HUMAN-LIKELY] shopify-zero-retailer#2927 (PR author: narvarjdibella) | 2025-08-11 | kind=review-body
Approved with minor changes

[HUMAN-LIKELY] shopify-zero-retailer#2965 (PR author: killalau) | 2025-08-19 | kind=review-body
Looks good to me. I wish we could break the logic and write test cases for this but maybe for later.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/graphql/queries/consumer/calculate_refund.rb:None
Yes, backend changes are not ready.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/data/calculateRefund.ts:None
I see. This does not work nested.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/data/submitReturn.ts:44
This is added to allow type compatibility. Since, return items can be ` ReturnCalculationInput | ReturnCalculationInput[]`, we need to account for both the cases.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/data/submitReturn.ts:64
This is added to allow type compatibility. Since, return items can be ` ExchangeItemInput | ExchangeItemInput[]`, we need to account for both the cases.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/data/submitReturn.ts:None
Since typescript cannot cast string into file, I added `any` but there is another work around:
`(ri.returnItem.pictures as unknown as File[])`. Let me know if that works better.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/pages/checkout/hooks/usePaymentIntent.ts:31
The type forces them to be. The caller has to provide valid values.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/pages/ExchangeMethods/ExchangeMethodOption.tsx:None
I wouldn't mind at all. I had just moved the function outside of the component.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | app/javascript/consumer-app/steps/ChooseExchangeMethod/ChooseExchangeMethod.tsx:None
Yes the initial state is an empty object like how it is for other variables. The `exchangeMethodOptions[0];` will be changed now post @jeetnarvar 's changes as there was no way to know if instant exchanges were available. I should have added a comment.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-comment | db/translations/en.csv:None
Thanks for reminding about this.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-20 | kind=review-body
Thanks for the review @killalau . We had new changes pushed earlier today by @chandrajeet including the retailer changes and backend changes. Unfortunately, they were not 100% ready but will be soon. I will look into the other consumer app related comments.

[HUMAN-LIKELY] shopify-zero-retailer#2919 (PR author: jeetnarvar) | 2025-08-21 | kind=review-comment | app/javascript/consumer-app/steps/Review/hooks/useNthFees.ts:18
We can add a new type later. There is no special handling for type TAX

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/steps/ChooseReturnCreditMethod/ChooseReturnCreditMethod.js:329
That's great

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/components/reshop/ReshopCreditOptionCard.js:50
Do we need this now post nth migration?

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/components/reshop/ReshopCreditOptionCard.js:1
It would be nice to have this in typescript

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/components/reshop/ReshopCreditOptionLabel.tsx:26
Can this be moved outside the component?

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/components/reshop/ReshopOnboarding.tsx:16
I'm assuming this URL does not change over time.

[HUMAN-LIKELY] shopify-zero-retailer#2989 (PR author: killalau) | 2025-08-28 | kind=review-comment | app/javascript/consumer-app/hooks/useCalculateRefundVariables.tsx:42
I like the refactor but is there any performance benefits here? I feel the queries will still be called the same amount of times. Also, could this be a part of useCalculateRefund itself?

[HUMAN-LIKELY] shopify-zero-retailer#2998 (PR author: killalau) | 2025-09-02 | kind=pr-comment
> > Should we add a check or gate keep for confirmation page? Do we have such information like return should be submitted?
> 
> @abhinavjainnarvar I think the main problem would be the new `goNext` action is too fragile and easy to cause bug if we called it twice. The original intension of `goNext` is to prevent using `goToStep(XXX)` where we have to specify the next step explicitly. It is inconvenience when we introducing new step (like my return onboarding step, and your instant exchange option step), we need to update many places to make sure the navigation is in the correct order.
> 
> Maybe a better approach would be having a new context on each step, the context would know its index (or the step name). The new context would provide the `goNext` action, which explicitly call `goToStep(XXX)` behind the scenes.

We need to revisit the redirection logic. You are right about the current structure leading to issues. I would prefer a centralized logic where we could manage redirections from pages so that its easier to test and also to add new changes.

[HUMAN-LIKELY] shopify-zero-retailer#2998 (PR author: killalau) | 2025-09-02 | kind=review-body
Should we add a check or gate keep for confirmation page? Do we have such information like return should be submitted?

[HUMAN-LIKELY] shopify-zero-retailer#3007 (PR author: killalau) | 2025-09-05 | kind=review-comment | app/models/return.rb:1696
Where is this variable used @killalau ?

[HUMAN-LIKELY] shopify-zero-retailer#3030 (PR author: killalau) | 2025-09-11 | kind=review-comment | app/javascript/consumer-app/steps/ChooseExchangeMethod/ChooseExchangeMethod.tsx:36
Nice refactoring

[HUMAN-LIKELY] shopify-zero-retailer#3030 (PR author: killalau) | 2025-09-11 | kind=review-comment | app/javascript/consumer-app/steps/ChooseShopNow/ChooseShopNow.js:117
Does this change have no effect? Also, should the default value be null if it is not passed?

[HUMAN-LIKELY] shopify-zero-retailer#3040 (PR author: killalau) | 2025-09-12 | kind=review-comment | app/javascript/consumer-app/steps/OnboardReturnCreditMethod/OnboardReturnCreditMethod.tsx:32
Should have mentioned this earlier but there is a type for state: `ReturnStepsState`. You can refer this in Review.tsx and we can add more types as we go. The location of the types can be updated later on.

[HUMAN-LIKELY] shopify-zero-retailer#3040 (PR author: killalau) | 2025-09-12 | kind=review-body
Looks good. Just left one comment.

[HUMAN-LIKELY] shopify-zero-retailer#3057 (PR author: killalau) | 2025-09-17 | kind=review-body
Looks good

[HUMAN-LIKELY] shopify-zero-retailer#3059 (PR author: killalau) | 2025-09-17 | kind=pr-comment
Looks good. Thanks for adding the generated schema as discussed on Slack.

[HUMAN-LIKELY] shopify-zero-retailer#3070 (PR author: killalau) | 2025-09-18 | kind=review-comment | app/javascript/consumer-app/steps/Review/components/ReviewSummaryContainer.tsx:None
Is it possible to move this code to `Review.tsx` and also create a separate hook for reshop? I wanted to create one during refactoring but couldn't prioritize it.

There will be some part of the code in Review.tsx and some in the hook. For example
```
const { handleReshopError } = useReshop();
if(reshopUnrecoverableError) {
   handleReshopError();
} else {
...
}
```

[HUMAN-LIKELY] shopify-zero-retailer#3070 (PR author: killalau) | 2025-09-18 | kind=review-body
Added one suggestion. Rest looks good

[HUMAN-LIKELY] shopify-zero-retailer#3074 (PR author: jeetnarvar) | 2025-09-22 | kind=review-comment | spec/system/consumer/submit_instant_exchange_spec.rb:None
Looks good. Can we add js:'headless here?
```suggestion
RSpec.describe 'submit instant exchange', js: 'headless', type: :system do
```

[HUMAN-LIKELY] shopify-zero-retailer#3092 (PR author: killalau) | 2025-09-25 | kind=review-comment | app/javascript/consumer-app/hooks/useCalculateRefundVariables.tsx:None
What do you think about placing this function in items.js?

[HUMAN-LIKELY] shopify-zero-retailer#3092 (PR author: killalau) | 2025-09-25 | kind=review-comment | app/javascript/consumer-app/hooks/useItemGroupings.tsx:75
Can we add some description to these functions?

[HUMAN-LIKELY] shopify-zero-retailer#3092 (PR author: killalau) | 2025-09-25 | kind=review-comment | app/javascript/consumer-app/hooks/useItemGroupings.tsx:None
Instead of a conditional operator can we just return the value from the function?

[HUMAN-LIKELY] shopify-zero-retailer#3092 (PR author: killalau) | 2025-09-25 | kind=review-comment | app/javascript/consumer-app/modules/items.js:None
We don't need to write else here. We can just return the values.

[HUMAN-LIKELY] shopify-zero-retailer#3092 (PR author: killalau) | 2025-09-25 | kind=review-body
There seems to be a lot of heavy business logic in this PR. The tests cases are written well so that gives more confidence. Otherwise, there is a good need of manual testing as well.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/data/capriCarrierService.js:24
Can we add the new API in [graphql.ts](https://github.com/narvar/shopify-zero-retailer/blob/develop/app/javascript/consumer-app/graphql/graphql.ts) and use `yarn generate:types` to generate the types? [Example](https://github.com/narvar/shopify-zero-retailer/blob/develop/app/javascript/consumer-app/pages/checkout/hooks/useCheckout.tsx#L11)

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:121
Can we add `labelAttributes` also in the variables list?
```suggestion
    [carrierId, credentials, isUat, labelAttributes, labelAttributesEnabled],
```

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:379
```suggestion
              onChange={() => updateDraft({
                  ...draft,
                  labelAttributesEnabled: !draft.labelAttributesEnabled,
              })}
```

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:18
Can we create a `styles.ts` or `CapriCredentialFormStyles.ts` file for the styles?

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:73
Can we declare the empty array outside the component and use it here? This is done to avoid side effects in future. If we had a useEffect which had `carrierAttributeOptions` as one of the values in the dependency list. It could create a lot of re renders since the object is created new every time(if the API is not called or is failed) and sometimes an infinite loop depending on the logic.

```suggestion
    //before component declaration
    const DEFAULT_LABEL_ATTRIBUTES = [];
    
    capriLabelAttributes?.data?.capriLabelAttributes || DEFAULT_LABEL_ATTRIBUTES;
```

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:99
If this or the functions below are pure function, we could put them outside the component as they are util functions and do not update the React's local state directly or call the component's props.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:188
Can we create a new component for this to break it down and make it easier to read? Maybe `LabelAttributesFormTableRow.tsx`

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:265
This value can be stored in `useMemo` and used here since it has .map and .filter in it which impacts the performance of the component.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/UPSForm.js:157
```suggestion
    [carrierId, credentials, labelAttributes, labelAttributesEnabled],
```

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/UPSForm.js:185
```suggestion
    const validLabelAttributes = useMemo(() => draft.labelAttributes.filter(
      (attr) => attr.carrierAttribute && attr.valueKey && attr.format,
    ), [draft.labelAttributes]);
```

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-25 | kind=review-body
Great work @prathameshVic. I've added few comments to improve the overall code quality. Also, can we add some test cases for the new components? Let me know if you need any help.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-29 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/LabelAttributesForm.js:99
Yes, the idea is to put it in the same component file but on in the component rendering flow to avoid re-declaration of functions.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-29 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/CapriCredentialForm.js:121
Oh, then there must be some other problem leading to it. We need to figure why there was an infinite loop.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-29 | kind=review-comment | app/javascript/retailer-app/data/capriCarrierService.js:24
@prathameshVic You are right. We haven't added it for retailer app. Thanks for reminding. This should have been done by now.

[HUMAN-LIKELY] shopify-zero-retailer#3095 (PR author: prathameshVic) | 2025-09-29 | kind=review-comment | app/javascript/retailer-app/pages/CredentialsForm/UPSForm.js:185
That's a fair point. I didn't realise it was inside handleFormSubmit, it is fine to be as it is then

[HUMAN-LIKELY] shopify-zero-retailer#3100 (PR author: narvarjdibella) | 2025-10-02 | kind=review-comment | app/lib/orders/order.rb:None
Can we move this to the MoneyUtil class as well?

[HUMAN-LIKELY] shopify-zero-retailer#3100 (PR author: narvarjdibella) | 2025-10-02 | kind=review-comment | app/lib/return_submission/item_builder.rb:None
nit: Maybe add a new function to take on the null values

[HUMAN-LIKELY] shopify-zero-retailer#3100 (PR author: narvarjdibella) | 2025-10-02 | kind=review-comment | app/lib/shop_now/checkout.rb:147
nit: Wrap this code after getting the min value with the money util.

[HUMAN-LIKELY] shopify-zero-retailer#3100 (PR author: narvarjdibella) | 2025-10-02 | kind=review-body
Changes look good. Great work on this @narvarjdibella 🥳

[HUMAN-LIKELY] shopify-zero-retailer#3185 (PR author: killalau) | 2025-10-27 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ItemsEditRow.js:None
nit: Store it in a variable

[HUMAN-LIKELY] shopify-zero-retailer#3185 (PR author: killalau) | 2025-10-27 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ItemsExchangeTable.js:None
Do we need the console.log

[HUMAN-LIKELY] shopify-zero-retailer#3185 (PR author: killalau) | 2025-10-27 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ItemsExchangeTable.js:163
Should we create a separate component for the nested loop to make it easier to read?

[HUMAN-LIKELY] shopify-zero-retailer#3185 (PR author: killalau) | 2025-10-27 | kind=review-body
Great work. Everything looks good. Added minor improvements.

[HUMAN-LIKELY] shopify-zero-retailer#3111 (PR author: jeetnarvar) | 2025-11-12 | kind=review-comment | app/javascript/retailer-app/locales/en/rules.json:312
@jeetnarvar We need to add this for other locales too. See app/javascript/retailer-app/locales/ai_instructions.md and pass it to your AI agent

[HUMAN-LIKELY] shopify-zero-retailer#3111 (PR author: jeetnarvar) | 2025-11-12 | kind=review-comment | app/javascript/retailer-app/pages/EligibilityRules/ExchangeWindowWidget.js:None
Can we add `syncPaymentProcessor` as dependency?

[HUMAN-LIKELY] shopify-zero-retailer#3111 (PR author: jeetnarvar) | 2025-11-12 | kind=review-comment | app/javascript/retailer-app/pages/EligibilityRules/ExchangeWindowWidget.js:444
I agree. Also, we can combine mutliple conditions and write further conditions if required. For example, we need just one 
```
{paymentRenderType == "stripe" &&
```

[HUMAN-LIKELY] shopify-zero-retailer#3210 (PR author: killalau) | 2025-11-17 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/editReturn.ts:84
@killalau Can we add test cases for this piece of code?
Nice work. Do we want to split into multiple items with quantity 1 or just one product with quantity 1 and one more with quantity n-1?

[HUMAN-LIKELY] shopify-zero-retailer#3210 (PR author: killalau) | 2025-11-17 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ExchangeSelectorModal.tsx:104
Great optimization here on filtering.

[HUMAN-LIKELY] shopify-zero-retailer#3210 (PR author: killalau) | 2025-11-17 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ExchangeSelectorModal.tsx:None
Can we use zod along with react-hook-form? Its present in this PR but the code is not merged yet: https://github.com/narvar/shopify-zero-retailer/pull/3231/files#diff-74243d0a72efdf7255c8399d15536391469d406562f9094f845d739ae4e41b6c
app/javascript/retailer-app/pages/RiseAiIntegrationSettings/RiseAiIntegrationSettings.tsx

[HUMAN-LIKELY] shopify-zero-retailer#3210 (PR author: killalau) | 2025-11-17 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ItemsEditTable.js:50
I am wondering why there was a compose earlier but this seem to make sense.

[HUMAN-LIKELY] shopify-zero-retailer#3210 (PR author: killalau) | 2025-11-17 | kind=review-body
@killalau Great work! I have added a couple of comments and I would recommend adding a few more tests to increase the coverage considering this is a big PR.

[HUMAN-LIKELY] shopify-zero-retailer#3300 (PR author: killalau) | 2025-11-28 | kind=review-comment | app/javascript/retailer-app/components/rules/AutomationTimingInput.tsx:33
@killalau Do we really need this to be a function?
Will this not work as expected and we need not call the function while rendering too?
```suggestion
    displayValue: t("refundMethod.form.automation.timing.options.approved")
```

One more solution to this could be having TIMING_OPTIONS to be a hardcoded object:

```
[
  {
    key: TIMING_OPTIONS_ENUM.APPROVED,
    value: "refundMethod.form.automation.timing.options.approved"
  }
]

const filteredTimingOptions = useMemo(
    () =>
      TIMING_OPTIONS.filter(
        (opt) => !availableTimings || includes(opt.key, availableTimings),
      ).map(opt => (opt["displayValue"] = t(opt["value"]))),
    [availableTimings, t],
  );

```

Please ignore the syntax errors and names.

[HUMAN-LIKELY] shopify-zero-retailer#3300 (PR author: killalau) | 2025-11-28 | kind=review-comment | app/javascript/retailer-app/components/rules/AutomationTimingInput.tsx:100
```suggestion
          {opt.displayValue}
```

[HUMAN-LIKELY] shopify-zero-retailer#3300 (PR author: killalau) | 2025-11-28 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/editReturn.test.ts:1
I know that we don't really have a proper structure for test cases in retailer-app but can we keep this file in the retailer-app/__tests__?

[HUMAN-LIKELY] shopify-zero-retailer#3300 (PR author: killalau) | 2025-11-28 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/editReturn.ts:127
We can avoid type casting here.

```suggestion

const automationTypes: (keyof ReturnAutomationsInput)[] = [
  "refund",
  "markAsPaid",
  "reserveInventory",
  "restock",
];

const buildAutomationConfig = (form: UseFormReturn<ReturnDraft>) => {
  let cfg: ReturnAutomationsInput | undefined = undefined;

  automationTypes.forEach((automationType) => {
    const timingPath =
      `refundAutomationState.${automationType}Timing` as keyof ReturnDraft;
    if (form.getFieldState(timingPath).isDirty) {
      cfg = set(
        [automationType, "timing"],
        form.getValues(timingPath),
        cfg ?? {},
      );
    }
  });
  return cfg;
};
```

[HUMAN-LIKELY] shopify-zero-retailer#3317 (PR author: narvarjdibella) | 2025-12-16 | kind=review-comment | app/javascript/consumer-app/modules/items.js:642
nit: Can we push this function outside the component so that it remains constant through out the executions and not required to be added as a dependency on useMemo. Remove the duplicate as well.

[HUMAN-LIKELY] shopify-zero-retailer#3380 (PR author: alanmacdougall-narvar) | 2026-01-08 | kind=review-comment | app/models/shop.rb:None
`undefined method positive?' for nil:NilClass (Return::RefundError)` when using even exchange with FF enabled

[HUMAN-LIKELY] shopify-zero-retailer#3271 (PR author: jeetnarvar) | 2026-01-09 | kind=review-comment | app/javascript/retailer-app/data/returnDetails.js:145
Timestamps
[Other fields if it is worth showing]

[HUMAN-LIKELY] shopify-zero-retailer#3424 (PR author: nurey) | 2026-01-24 | kind=review-comment | app/javascript/shared/components/SafeLink.js:None
We can either remove `!href` condition or default it to empty string. The normal behaviour with href="#" would help scroll to the top. Not sure if we should prevent that

[HUMAN-LIKELY] shopify-zero-retailer#3445 (PR author: killalau) | 2026-01-30 | kind=review-comment | app/javascript/consumer-app/providers/NthProviders.tsx:69
While we are doing this, do you think we can change the calling pattern here. We could memoize the result of the querySettings and pass the value here. Same goes for other functions in the component.

[HUMAN-LIKELY] shopify-zero-retailer#3445 (PR author: killalau) | 2026-01-30 | kind=review-comment | app/javascript/consumer-app/contexts/nthContext/useBuildTranslations.ts:82
Great work in cleaning this up. It would be nice to move translations out of here since we have migrated nth components. It might be a heavier task and could be done separately.

[HUMAN-LIKELY] shopify-zero-retailer#3445 (PR author: killalau) | 2026-01-30 | kind=review-body
Great work on cleaning this up!

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.tsx:108
Add error field handling for `settingsQueryStatus`

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
Use useSnackbarEffect for snackbar
```
import { useSnackbarEffect } from "../../shared/modules/hooks";
```

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.tsx:189
Add `setUpdatingSettings` as a dependency

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
Can we remove `setUpdatingSettings(false)` and use `settingsMutationStatus.loading` state?

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
Change it to `body1` or remove it unless necessary. You can double check the theme configuration for this.

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
Use mutation loading status instead of updatingSettings

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
Use spinner instead
```
import Spinner from "../../../shared/components/Spinner";
```

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/retailer-app/pages/ShopifyCollectiveFulfillments/ShopifyCollectiveFulfillments.js:None
We don't need a fallback if `collectiveSettings.displayReturnItemShopifyCollectiveVendorName` is a boolean field. Double check once converted to TS.

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-comment | app/javascript/consumer-app/pages/ItemSelector/helper.tsx:None
Also, check the properties of item and add `shopifyCollectiveVendorName` in that typescript interface. 
```
const vendorName =
    "shopifyCollectiveVendorName" in item
      ? (item.shopifyCollectiveVendorName ?? "")
      : "";
```

[HUMAN-LIKELY] shopify-zero-retailer#3447 (PR author: narvarjdibella) | 2026-01-30 | kind=review-body
Good work on the UI. We can convert javascript to typescript files and other minor changes.

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/data/globalVersionHistory.ts:None
Add this to the top of the component to avoid re-renders or memo triggers.
```
const DEFAULT_VERSIONS: Version[] = [];
```

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/versionHistoryTypes.ts:None
Lets remove unknown and be specific about the possibility of types here. If there are multiple from which behave similar, we could create a type for `from` and `to` as well and use them instead.

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/versionHistoryTypes.ts:18
```
export type Field = {
  field: string;
};

export type FieldToFromChange = Field & {
  from: unknown;
  to: unknown;
};

export type OpaqueFieldChange = Field & {
  changed: boolean;
};

export type ConditionFieldChange = Field & {
  conditionChanges: ConditionChange[];
};

export type FieldChange =
  | FieldToFromChange
  | OpaqueFieldChange
  | ConditionFieldChange;
```

Suggestion: Conditional type handling

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
We can use the enums here

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/versionHistoryUtils.ts:None
Double check if this is okay to show to the user

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/versionHistoryUtils.ts:1
Write test cases for the utils and for other components as well.

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:1
Considering there are 4 components, we could split into 2 files.

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistoryItem.tsx:None
We can translate the string

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistoryItem.tsx:None
```suggestion
}: GlobalVersionHistoryItemProps) {
```
It is not required.

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistoryItem.tsx:None
```suggestion
      {ruleChanges.map(({ label, rules, evaluationType }) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistoryItem.tsx:None
```suggestion
          {settingsChanges.map(({ field, from, to }) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistorySection.tsx:None
```suggestion
function GlobalVersionHistorySection() {
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistorySection.tsx:None
```suggestion
          onClick={(e) => {
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/GlobalVersionHistorySection.tsx:None
```suggestion
            versions.map((version) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
}: FieldChangeItemProps) {
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
          {conditionChanges.map((condChange, idx) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
      {fieldChanges?.map(({ field, from, to }) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:198
```suggestion
}: RuleLabelProps) {
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:241
```suggestion
}: RuleChangesListProps) {
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
      {rules.map((rule) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
              {rule.fields?.map((fieldChange) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-comment | app/javascript/retailer-app/components/rules/RuleChangesList.tsx:None
```suggestion
            rule.fields?.map((fieldChange) => (
```
Redundant

[HUMAN-LIKELY] shopify-zero-retailer#3412 (PR author: nurey) | 2026-02-02 | kind=review-body
Great work at finishing the frontend changes. I've adde some redundant non-blocking comments for types which are not needed to be explicitly mentioned as they are derived by Typescript. 

We can have use cases for explicit mentioning helps like having a shared function or a component with a specific type but these are not one of those cases.

[HUMAN-LIKELY] shopify-zero-retailer#3473 (PR author: jeetnarvar) | 2026-02-06 | kind=review-comment | app/lib/shop_now/checkout.rb:163
The other parts of the code use `shop_now_cart_cost`. Should they be refactored as well?

[HUMAN-LIKELY] shopify-zero-retailer#3473 (PR author: jeetnarvar) | 2026-02-06 | kind=review-body
Looks good. Take a look at one of the comments and Copilot feedback as well.

[HUMAN-LIKELY] shopify-zero-retailer#3471 (PR author: jeetnarvar) | 2026-03-03 | kind=review-comment | app/javascript/consumer-app/steps/Review/components/OrderDetails.tsx:168
Why do we have "-" in the amount?

[HUMAN-LIKELY] shopify-zero-retailer#3471 (PR author: jeetnarvar) | 2026-03-03 | kind=review-comment | app/javascript/consumer-app/steps/Review/components/ReviewSummaryContainer.tsx:230
Same question here

[HUMAN-LIKELY] shopify-zero-retailer#3471 (PR author: jeetnarvar) | 2026-03-03 | kind=review-body
Looks good. One clarification added for the amount

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-09 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRuleForm/ReturnLocationRuleForm.tsx:1
@prathameshVic Can we convert the new javascript files to typescript? You can refer: ShopifyCollectiveFulfillments.tsx and app/javascript/retailer-app/pages/ReturnDetails/RefundAutomationEditor.tsx as an example.

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRuleForm/ReturnLocationRuleForm.tsx:1
@prathameshVic I am taking a look at it now.

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnMethodRuleForm/ReturnMethodRuleForm.js:None
nit: We can use shorthand here:

```suggestion
      <>
      </>
```

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRules/ReturnLocationRulesTable.tsx:None
Can we check the type casting here? We shouldn't need to cast a type here. If the type is really unknown, then lets add handling on the basis of that.

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/data/returnLocationRules.ts:1
Can we convert this to typescript as well? It will resolve some of the issues we are facing in the components with type casting. You can refer ruleVersionHistory.ts

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRules/ReturnLocationRules.tsx:55
This should be resolved after we resolve the above comment after converting it to ts

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRules/ReturnLocationRules.tsx:None
Why do we need to memoize it here? Any reason that we cannot render it directly in the component?

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/pages/ReturnLocationRules/ReturnLocationRules.tsx:None
nit: Shorthand fragment
```suggestion
    <>
```

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/components/rules/utils.js:1
The test case did not exist from earlier but I feel we should write test cases for this file and for the new components too

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-comment | app/javascript/retailer-app/__tests__/pages/ReturnMethodRuleForm.spec.js:41
👍

[HUMAN-LIKELY] shopify-zero-retailer#3549 (PR author: prathameshVic) | 2026-03-12 | kind=review-body
Looks good. Few changes needed to wrap up. Great work Prathamesh!

[HUMAN-LIKELY] shopify-zero-retailer#3581 (PR author: narvarjdibella) | 2026-03-13 | kind=review-comment | app/javascript/retailer-app/data/giftReturnsPreferences.js:None
Since, Apollo will just omit undefiend values, we can write this
```suggestion
        hideGiftReturnLink: params?.hideGiftReturnLink,
```

[HUMAN-LIKELY] shopify-zero-retailer#3581 (PR author: narvarjdibella) | 2026-03-13 | kind=review-comment | app/javascript/retailer-app/data/giftReturnsPreferences.js:None
Convert this function to async. This will help refactor `.then` in the function below
```suggestion
    async (params) => {
```

[HUMAN-LIKELY] shopify-zero-retailer#3581 (PR author: narvarjdibella) | 2026-03-13 | kind=review-comment | app/javascript/retailer-app/data/giftReturnsPreferences.js:None
Refactor to remove `.then` but I am not sure the intent for conditional updating of cache. We can discuss that and is it expected to not update for null values?
```suggestion
       const result = await edit({ variables });
       if (Object.hasOwn(params, "hideGiftReturnLink")) {
        updateCacheForPublish(client.cache);
      }
```

[HUMAN-LIKELY] shopify-zero-retailer#3608 (PR author: nurey) | 2026-03-19 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/RulesApplied/RuleCard.tsx:None
@nurey I think the main issue is the unknown type. Lets discuss on how to fix this.

[HUMAN-LIKELY] shopify-zero-retailer#3608 (PR author: nurey) | 2026-03-19 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/ReturnDetailsBase.js:661
I like the idea of ErrorBoundary. We have one in general for Retailer App. We usually don't need it for specific features especially when typescript is involved as there are hardly any runtime errors but in the case where the types are unknown, any or not validated, this can happen.

[HUMAN-LIKELY] shopify-zero-retailer#3608 (PR author: nurey) | 2026-03-19 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/RulesApplied/RuleCard.tsx:None
```suggestion
const formatValues = (values: Condition["values"]): string => {
```

[HUMAN-LIKELY] shopify-zero-retailer#3608 (PR author: nurey) | 2026-03-19 | kind=review-body
I would recommend going through all the types and making sure they are in sync with the backend graphql schema. If they are in sync and given that we don't have any unsafe type cast in our flow(I double checked and we don't), we don't need error boundary since there wont be any runtime errors.

[HUMAN-LIKELY] shopify-zero-retailer#3622 (PR author: jaredbeck) | 2026-03-23 | kind=review-body
JS Lgtm! Great work

[HUMAN-LIKELY] shopify-zero-retailer#3619 (PR author: jeetnarvar) | 2026-03-24 | kind=review-comment | app/lib/shop_now/checkout.rb:615
@jeetnarvar I would like to understand how does this reordering make any difference since the previous 2 statements are independent of it?

[HUMAN-LIKELY] shopify-zero-retailer#3619 (PR author: jeetnarvar) | 2026-03-24 | kind=review-comment | app/lib/shop_now/checkout.rb:279
@jeetnarvar I would like to understand this reasoning for this change. Is this related to the bug or is it just a general improvement?

[HUMAN-LIKELY] shopify-zero-retailer#3619 (PR author: jeetnarvar) | 2026-03-24 | kind=review-body
I have left a couple of comments. Thanks for adding a lot of test cases.
In general, I'd recommend adding a description or a comment addressing some specific changes if they are not obvious so that it is easier to review.

[HUMAN-LIKELY] shopify-zero-retailer#3654 (PR author: jaredbeck) | 2026-03-31 | kind=review-comment | app/models/shop.rb:None
Move this below the normalization function call to make sure the data formats are same.

[HUMAN-LIKELY] shopify-zero-retailer#3654 (PR author: jaredbeck) | 2026-03-31 | kind=review-comment | app/models/shop.rb:None
Please revisit the object comparison logic

[HUMAN-LIKELY] shopify-zero-retailer#3654 (PR author: jaredbeck) | 2026-03-31 | kind=review-body
LGTM! Couple of comments added for improvement.

[HUMAN-LIKELY] shopify-zero-retailer#3666 (PR author: alanmacdougall-narvar) | 2026-04-08 | kind=review-comment | app/javascript/retailer-app/pages/ReturnDetails/RulesApplied/RuleCard.tsx:None
```suggestion
   const ruleAttributes = isMatchedRule(rule) ? rule.ruleAttributes : undefined;
```

[HUMAN-LIKELY] shopify-zero-retailer#3666 (PR author: alanmacdougall-narvar) | 2026-04-08 | kind=review-body
Looks good. Can we add some test cases too for the changes?

[HUMAN-LIKELY] shopify-zero-retailer#3669 (PR author: nurey) | 2026-04-08 | kind=review-body
Approving assuming the changes have been tested. You can attack screenshots for such changes. It becomes easier to review.

[HUMAN-LIKELY] shopify-zero-retailer#3677 (PR author: jaredbeck) | 2026-04-08 | kind=review-body
LGTM! Great cleanup

[HUMAN-LIKELY] shopify-zero-retailer#3687 (PR author: nurey) | 2026-04-13 | kind=review-body
Looks like we are bringing back the height calculation logic. LGTM!

[HUMAN-LIKELY] shopify-zero-retailer#3689 (PR author: jaredbeck) | 2026-04-13 | kind=review-body
Lgtm!

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/.env.development.local.example:25
Nice 👍

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/src/routes/__root.tsx:None
@killalau Should we add policies that are followed in retailer app too?
```js
export default {
  typePolicies: {
    Banner: {
      keyFields: ["key"],
    },
  },
};

```

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/src/lib/error-codes.ts:1
@killalau We have removed `generalError` compared to our retailer app. Is that intentional? Also, can we sort this alphabetically

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/vite.config.ts:29
Should we add the alias in vitest.config.ts too?

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/package.json:19
Would it be challenging to use apollo v4 here?

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/src/routes/__root.tsx:None
Also, what about this? Do we need this?

```js
if (process.env.NODE_ENV === "development") {
    window.secretVariableToStoreCache = cache;
  }
```

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-comment | apps/shopify-retailer/src/lib/error-notifier.ts:9
I see a lot of unknown params. What is the scope of this errorNotifier? Is it just a replacement for console log? Should we check the patterns across denali for these things?

[HUMAN-LIKELY] denali#2194 (PR author: killalau) | 2026-05-20 | kind=review-body
Great work. Added few comments worth looking at.

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/components/SessionExpiredModal/SessionExpiredModal.tsx:23
@killalau Will fetching shop user be a generic requirement across our repo? We could create a small ticket just to add fetch shop user info so that it is loaded as soon as the app is loaded and we can test this modal as well.

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/AGENTS.md:None
We can remove the ticket number here as this is just informational for Claude.

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/lib/error-notifier.ts:115
@killalau Shouldn't we be accepting an error object instead so that rollbar can log with trace? Tthe messageAttribute || (msg as string) fallback means the Error object is only passed through when error.message is empty so errors with messages lose stacks and errors without messages keep them.

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/lib/apollo.ts:None
Wouldn't this also a produce a plain object with no stack? Should we be passing the error object to get the benefits of rollbar stack trace?

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/components/SectionErrorBoundary/SectionErrorBoundary.tsx:None
Should we just decide the component in if else or switch and just have return once?

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/dev/shopifyBridgeStub.ts:None
We can update the imports after my recent changes to '@lib/logger'

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/lib/apollo.ts:1
Should we add a test case for this file too considering it has decent complexity in logical statements that should be tested?

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/AGENTS.md:None
Nice documentation 🥇

[HUMAN-LIKELY] denali#2300 (PR author: killalau) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/AGENTS.md:None
I think this would be good to move to its own document that talks about error handling in detail but not sure if we need all the details in this file. What do you think? @killalau

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-04 | kind=review-comment | apps/shopify-retailer/docs/coordinator.md:1
Good reorganization 👍

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/const/permissions.ts:18
This should not be exported and used for comparison as it is in szero. Also, I feel we should not be adding all the routes yet as there is a possibility of things will shuffle around in Denali and we can add this when we are working on that particular migration. We can make a note in migration file too.

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/lib/legacy/VENDORED.md:None
Should we update this as well after updating ANY_PERMISSIONS above?

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/config/fetchConfig.ts:44
Nice

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/lib/legacy/hooks.js:1
@killalau This is nice. Should we convert the straight forward ones to TS? What do you think? Also, would it make more sense to migrate once we actually ship related code?

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/docs/porting-data-hooks.md:243
Great 👍

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/graphql/query/GetChangesAwaitingPublish.graphql:1
@killalau Any reason to add this change in this PR?

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-comment | apps/shopify-retailer/src/const/permissions.ts:18
By "this", I meant ANY_PERMISSIONS in PERMISSIONS constant.

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-body
LGTM! Minor comments added.

[HUMAN-LIKELY] denali#2408 (PR author: killalau) | 2026-06-05 | kind=review-body
Great work @killalau

===== SECTION B: PR descriptions (human-likely) =====
[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-11-29 | kind=pr-description
![image](https://github.com/user-attachments/assets/37597d9e-e018-47d9-b2fe-3993449de91d)

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=pr-description
The calculations shown will be fixed soon.
![image](https://github.com/user-attachments/assets/ed805604-4c10-4a85-876d-ad733d06c73e)

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-04 | kind=pr-description
![image](https://github.com/user-attachments/assets/c001dcc2-2aef-4c44-9492-cc6c524fe870)

![image](https://github.com/user-attachments/assets/f88bf31e-5cf1-40d2-94ad-2c024a078933)

[HUMAN-LIKELY] shopify-zero-retailer#2273 (PR author: abhinavjainnarvar) | 2024-12-12 | kind=pr-description
To see chameleon builder, one has to be logged in to Narvar chameleon on the same browser and add a query param `chameleon=xxxx`. For eg: `chameleon=true`.

![image](https://github.com/user-attachments/assets/4c036be7-fa67-4ff9-912a-5f30a2ba51b6)

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-16 | kind=pr-description
The feature is not complete. Success/Error handling, redirection and metrics are remaining.

![image](https://github.com/user-attachments/assets/681d1f18-a7fc-4b67-b510-04aa098e6a1d)


![image](https://github.com/user-attachments/assets/f69de539-491a-46ca-96ed-45a81c4581ea)

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-18 | kind=pr-description
This PR has 462 files changed but most of them are due to change in lint configuration. There are some packages added as well to enforce standard rules.

**For a quick review, I have added comments in the PR on the most important part of the configuration change.** 
If you'd like to see changes in detail. I have added commits with the change title.

[HUMAN-LIKELY] shopify-zero-retailer#2410 (PR author: abhinavjainnarvar) | 2025-02-21 | kind=pr-description
![image](https://github.com/user-attachments/assets/6630c7d0-71b2-4868-b07c-7058368ce499)
![image](https://github.com/user-attachments/assets/96772388-5b88-4cd2-a2cc-f3380c04fb7a)

[HUMAN-LIKELY] shopify-zero-retailer#2415 (PR author: abhinavjainnarvar) | 2025-02-24 | kind=pr-description
![image](https://github.com/user-attachments/assets/c4a2bca2-f308-4f76-9b0c-482b5f582a28)

[HUMAN-LIKELY] shopify-zero-retailer#2424 (PR author: abhinavjainnarvar) | 2025-02-27 | kind=pr-description
![image](https://github.com/user-attachments/assets/6c108c91-aee9-4eec-a578-8590a4688308)

[HUMAN-LIKELY] shopify-zero-retailer#2439 (PR author: abhinavjainnarvar) | 2025-03-04 | kind=pr-description
![image](https://github.com/user-attachments/assets/e74bf745-3f50-483e-8e5b-e946c0bc9e83)

![image](https://github.com/user-attachments/assets/563aec32-05a7-46b5-8d13-dc8a06cdfa18)

[HUMAN-LIKELY] shopify-zero-retailer#2460 (PR author: abhinavjainnarvar) | 2025-03-07 | kind=pr-description
Return method rules
![image](https://github.com/user-attachments/assets/80b8ee31-c9da-4d73-9762-c39e3d1aaf63)
![image](https://github.com/user-attachments/assets/1e072757-0065-413c-a8b8-56aafae3babd)

Refund method rules
![image](https://github.com/user-attachments/assets/8bb307c9-9f61-47a5-a9f5-1cb7bc71851b)
![image](https://github.com/user-attachments/assets/de907e71-2b37-4a94-b1b4-de979b76dab2)
![image](https://github.com/user-attachments/assets/0468c677-8ca6-4c5b-b62e-65cba177fbb3)
![image](https://github.com/user-attachments/assets/67e31595-401b-4ac8-88da-9a41992cd52f)
![image](https://github.com/user-attachments/assets/5826ddd1-4c32-4f25-854c-138eedceeb4b)

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-03 | kind=pr-description
<img width="1183" alt="image" src="https://github.com/user-attachments/assets/d37a86c0-280f-454d-9953-3982120f3799" />

[HUMAN-LIKELY] shopify-zero-retailer#2946 (PR author: abhinavjainnarvar) | 2025-08-11 | kind=pr-description
<img width="360" height="229" alt="image" src="https://github.com/user-attachments/assets/bd8656ca-4770-4f98-b932-36df33cda08c" />

===== SECTION C: replies on his own PRs (human-likely) =====
[HUMAN-LIKELY] shopify-zero-retailer#2177 (PR author: abhinavjainnarvar) | 2024-11-06 | kind=review-comment | app/lib/webhooks/outgoing/payload_v3.rb:None
For metrics, we are using the original return item quantity: https://github.com/narvar/shopify-zero-retailer/blob/develop/app/lib/metrics/exchange_refund_metric.rb#L34

[HUMAN-LIKELY] shopify-zero-retailer#2193 (PR author: abhinavjainnarvar) | 2024-11-11 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:668
Sign not required as the fees would always be shown positive if they are charged to the user and negative if they are refunded to the user.

[HUMAN-LIKELY] shopify-zero-retailer#2193 (PR author: abhinavjainnarvar) | 2024-11-11 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:682
Same pattern. Positive if charged and negative if refunded

[HUMAN-LIKELY] shopify-zero-retailer#2193 (PR author: abhinavjainnarvar) | 2024-11-11 | kind=review-comment | config/initializers/money.rb:86
By default, negative sign would always come before the currency symbol. Earlier, if it was `$-4.00`, it will now be `-$4.00`

[HUMAN-LIKELY] shopify-zero-retailer#2177 (PR author: abhinavjainnarvar) | 2024-11-19 | kind=review-comment | app/lib/webhooks/outgoing/payload_v3.rb:None
I was under the assumption that a lot of exchange item attributes share the information with the original item so /I decided to include but I have removed them now. I had already added `new_product_*` fields which were applicable. Thanks for the review.

[HUMAN-LIKELY] shopify-zero-retailer#2177 (PR author: abhinavjainnarvar) | 2024-11-19 | kind=review-comment | spec/lib/webhooks/outgoing/payload_v3_spec.rb:None
@narvarjdibella I like the suggestion and I had started with that considering there is no major business logic for exchange item fields in the webhook payload_v3. But we decided from our conversation to create a new one as the other test cases were not considering comparing `exchange` object fields and a new one could help track new fields in the future as well.

Looking back at the code, I feel we should have 2 cases to be tested by default: one with exchange and one without. I feel I'll leave the test cases as it is for now.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-25 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:1
Dummy component to test the flow.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-25 | kind=review-comment | app/javascript/consumer-app/components/CssBaseline.js:1
Lint fixes from here based on neohub standards.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-25 | kind=review-comment | tsconfig.json:1
Added tsconfig.json

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-26 | kind=review-comment | .eslintrc.js:94
Yes, I have merged both now.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-26 | kind=review-comment | .eslintrc.js:43
Yes. There were lot of errors after updating the packages. So, I removed some of them.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-26 | kind=review-comment | .eslintrc.js:52
Yes, it created some errors. We could fix them in future PRs.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-26 | kind=review-comment | .eslintrc.js:None
Most of our existing components have `.jsx` in `.js` files so I decided to add this but looks like it doesn't make any difference without as well.

[HUMAN-LIKELY] shopify-zero-retailer#2220 (PR author: abhinavjainnarvar) | 2024-11-26 | kind=review-comment | .eslintrc.js:None
Adding this 
```
"react/jsx-filename-extension": [
      1,
      { extensions: [".js", ".jsx", ".tsx"] },
    ],
```

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-02 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useTransformToNth.ts:14
hardcoded object. Will be deleted in the follow up PR

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-02 | kind=review-comment | app/javascript/consumer-app/components/AppRouter.js:41
This can be restructured later to have nested routes but this serves the purpose as of now with just one route.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-02 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:76
These lint changes are annoying and are added only to the files I saved because of my sad prettier configuration. I have disabled in future work.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/steps/Review/Review.js:76
Yes, both of them are swtiched off from now on.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/util/transformToNth.ts:29
Thanks for pointing it out. I'll confirm again.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/hooks/useNthFees.js:6
These are old files. Got pushed by mistake.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/shop-now/data.js:181
Yes, I think it was not required so far. It will be used is v2.

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/controllers/cloud_task_controller.rb:547
How about `shop.app_proxy_url` here?

[HUMAN-LIKELY] shopify-zero-retailer#2239 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:30
I didn't understand the naming convention here.

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:32
Previous PR changes

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:55
Dummy click to test mutation API

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/controllers/cloud_task_controller.rb:None
Changes includes one from previous PR. This has double https `https://https://`. Will be removed in the future PR.

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/controllers/app_proxy_controller.rb:27
These params will be visible in the browser and thats why using `t` and `c`. The iframe params will be named different.

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:41
These are the iframe params

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/consumer-app/checkout/util/transformToNth.ts:22
Will be removed soon

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-03 | kind=review-comment | app/javascript/gql/__generated__/controlPlane.ts:1
I am looking for a better name for this. How about `schema.ts`?

[HUMAN-LIKELY] shopify-zero-retailer#2246 (PR author: abhinavjainnarvar) | 2024-12-04 | kind=review-comment | package.json:None
Good catch. Should have added it in dev

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-09 | kind=review-comment | app/javascript/consumer-app/steps/Review/useNthFees.js:34
Reverting these changes as they caused some issues.

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-10 | kind=review-comment | app/controllers/cloud_task_controller.rb:None
I wasn't aware of retailers calling it directly. Will they also be seeing shop_now_2 checkout pages? I'll need more details on this part.

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-10 | kind=review-comment | app/javascript/consumer-app/checkout/Checkout.tsx:None
Typescript accepts the above but I found it weird that it accepts `errors[0]` even though the number of elements can be 0. It threw error on execution so I added extra condition but I found a better workaround
```
  const error = checkoutData?.shopNowV2Checkout.errors[0]?.message ?? "";
```

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-10 | kind=review-comment | app/javascript/consumer-app/checkout/util/transformToNth.ts:124
So there will be only one reason returned from the backend. I hope it takes care of child reason too. I am just putting a structure to it. @jeetnarvar What do you think?

[HUMAN-LIKELY] shopify-zero-retailer#2247 (PR author: abhinavjainnarvar) | 2024-12-10 | kind=review-comment | app/controllers/cloud_task_controller.rb:None
Update post discussion: Encoding will be added on the backend for `webUrl`.

[HUMAN-LIKELY] shopify-zero-retailer#2273 (PR author: abhinavjainnarvar) | 2024-12-12 | kind=review-comment | app/views/app_proxy/index.html.erb:None
That's right. This doesn't have any impact. Only for customers.

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-16 | kind=review-comment | app/javascript/consumer-app/checkout/Payment.tsx:1
This component is not used as of now. Will be added to `Checkout` as I add more complexity.

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-17 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useAddress.ts:None
That's something I have to follow up and discuss. Some of these fields are present in Review.js. My understanding is that `address` is the original one while `newAddressDraft` is the one that is modified in the input fields. I couldn't really wrap up my mind around why the addresses are merged too.

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-17 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useAddress.ts:None
I think we definitely can if there is no other use case for `setAddress`. As of now, it is not but I think there are some parts which are still not clear.

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-17 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/usePayment.ts:25
Sure, I don't see any harm in that.

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-17 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useSubmit.ts:96
There is no one catching the error after this as this will be the `onSubmit` function. As you mentioned, the error state can be stored and handled separately. Throwing error will break the code and will be caught by Error Handler.

Is there any specific reason to throw the error?

[HUMAN-LIKELY] shopify-zero-retailer#2283 (PR author: abhinavjainnarvar) | 2024-12-18 | kind=review-comment | app/javascript/consumer-app/checkout/hooks/useSubmit.ts:96
> I think uncaught error in promise won't break the code.

That's correct. It will not break but it will go unhandled. As you said, my plan was to create a new `useMetircs` and then I'll connect it with the `useSubmit` hook. I think that works for both of us.

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | .prettierrc.js:9
This will add parentheses around function arguments with just one argument.
Before:
```
const square = s => s*s;
```
After:
```
const square = (s) => s*s;
```

The parentheses create consistency and cleaner git diffs.

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:1
Added flat config in accordance with eslint v9+

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:69
Use complete path for material-ui import errors.
Before:
```
import { Divider } from "@material-ui/core";

```
After:
```
import Divider from "@material-ui/core/Divider";

```

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:60
This will throw all the errors based on the rules mentioned in .prettierrc.js

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:51
This will help identify some import errors like:
```
import makeStyles from "@material-ui/core/styles/makeStyles";
```
No such path exists

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:18
In the earlier eslint versions, we used to have `env` to provide list of global settings. It is moved here now and `globals` package provides a concrete list of functions which should be available across the project. The others that are not covered are added below.

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:35
This is the material ui imports plugin that forces to use complete path. It is a good practice and also helpful in tree shaking.

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | eslint.config.ts:83
These are all the rules specific to `Typescript` files and the ones that are off are intentional as there are some `Javascript` functions used as well in the `Typescript` code.

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | package.json:79
Added `jitti` for `eslint` typescript configuration.
https://eslint.org/docs/latest/use/configure/configuration-files#typescript-configuration-files

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | package.json:174
Plugin to enforce material ui complete path while importing

[HUMAN-LIKELY] shopify-zero-retailer#2403 (PR author: abhinavjainnarvar) | 2025-02-19 | kind=review-comment | package.json:73
Package to provide an extensive list of global functions available to be used in a Browser run Javascript project.

[HUMAN-LIKELY] shopify-zero-retailer#2410 (PR author: abhinavjainnarvar) | 2025-02-21 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/Items.tsx:None
There are a few more but not a lot. We can add it now or we can do it step by step. I'm okay either way but I thought it would be quicker to move like this and replacing the dist reference going forward.

[HUMAN-LIKELY] shopify-zero-retailer#2410 (PR author: abhinavjainnarvar) | 2025-02-21 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/Items.tsx:None
List of things imported from `dist` folder
```
import { StickyFooterOnShowEvent } from "@narvar/nth-kit-returns-headless/dist/src/components/StickyFooter/types";
import { UserRoles } from "@narvar/nth-kit-returns-headless/dist/src/utils/auth";
import { PreferencesStatus } from "@narvar/nth-kit-returns-headless/dist/src/components/Preferences/types";
import { useViewportConfig } from "@narvar/nth-kit-returns-headless/dist/src/providers/ViewportConfigProvider";
import { useReturnsConfig } from "@narvar/nth-kit-returns-headless/dist/src/providers/ReturnsConfigProvider";
import useLanguage, {
  LanguageType,
} from "@narvar/nth-kit-returns-headless/dist/src/hooks/useLanguage";
import {
  useHipaaSubmitReturnCartMutation,
  useSubmitReturnCartMutation,
  Fee,
  OrderItem,
  SubmittedReturn,
  Location,
  ReturnCart,
  CurrencyAmount,
  PudoOption,
  PudoOptionInput,
  Location,
  SelectedPudoOption,
  DayOfWeek,
  OpeningHours,
  AdditionalProperty,
  Maybe,
  PudoOption,
  PudoOptionInput,
  ReturnCart,
  SetPudoOptionMutation,
  SetPudoOptionMutationVariables,
  SetPudoOptionDocument,
  HipaaSetPudoOptionMutation,
  HipaaSetPudoOptionMutationVariables,
  HipaaSetPudoOptionDocument,
} from "@narvar/nth-kit-returns-headless/dist/src/graphql/generated";
```

[HUMAN-LIKELY] shopify-zero-retailer#2410 (PR author: abhinavjainnarvar) | 2025-02-24 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/Items.tsx:None
Yeah. It would be nice to have as many. Can do it incrementally

[HUMAN-LIKELY] shopify-zero-retailer#2415 (PR author: abhinavjainnarvar) | 2025-02-25 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/ReviewSummaryRaw.tsx:None
@killalau I would for go for onChange too if there were some additional logic but the functions here are just setting the values and do not have any side effect. Let me know if it still doesnt

[HUMAN-LIKELY] shopify-zero-retailer#2415 (PR author: abhinavjainnarvar) | 2025-02-25 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/components/ClaimAttestation/ClaimAttestation.tsx:None
I couldn't find for the overall sections. Let me check if there are for some other elements.

[HUMAN-LIKELY] shopify-zero-retailer#2415 (PR author: abhinavjainnarvar) | 2025-02-26 | kind=review-comment | db/translations/en.csv:594
Let me know if these naming and prelude looks fine. @killalau

[HUMAN-LIKELY] shopify-zero-retailer#2415 (PR author: abhinavjainnarvar) | 2025-02-26 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/ReviewSummaryRaw.tsx:None
I am updating as you said considering if we add more logic to it in future, we won't have to update the name

[HUMAN-LIKELY] shopify-zero-retailer#2424 (PR author: abhinavjainnarvar) | 2025-02-27 | kind=review-comment | app/javascript/consumer-app/ReviewSummary/ReshopOptIn/ReshopOptInStyles.ts:31
Just added names to some of the styles which were creating warnings.

[HUMAN-LIKELY] shopify-zero-retailer#2439 (PR author: abhinavjainnarvar) | 2025-03-04 | kind=review-comment | app/javascript/retailer-app/pages/LanguageReturnReasons/Content.js:None
This needs to be changed once we have id coming from the backend

[HUMAN-LIKELY] shopify-zero-retailer#2460 (PR author: abhinavjainnarvar) | 2025-03-11 | kind=review-comment | app/javascript/retailer-app/pages/RefundMethodRuleForm/RefundMethodRuleForm.js:150
I think it would be an overkill. The dependency array has 3 values: `[rule, translationsFullKeyMap, defaultLocale]`. The change will be most likely due to `rule` so it should be fine to have the map again.
Adding a memo with `[conditions, isClaim]` could be an overhead.

[HUMAN-LIKELY] shopify-zero-retailer#2460 (PR author: abhinavjainnarvar) | 2025-03-11 | kind=review-comment | app/javascript/retailer-app/pages/ReturnMethodRuleForm/ReturnMethodRuleForm.js:102
Same logic here

[HUMAN-LIKELY] shopify-zero-retailer#2473 (PR author: abhinavjainnarvar) | 2025-03-13 | kind=pr-comment
> Besides the folder structure, do we have a plan to migrate the tests in nth? I believe all tests under `nth-kit-returns-headless` were written by me. Some complex components and logic, like reason picker, and exchanges require tests.

Thanks for the comments Franky. As I am still in the migration, I wanted to keep migrated stuff in the ReviewSummary component itself to keep track. Also, I am already looking into the test cases. Little complicated but it should be fine.

I will later move into a new folder structure. We can both come and discuss the new structure then. Let me know if it makes sense.

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-03 | kind=review-comment | app/javascript/retailer-app/data/userManagement.js:None
Removed the permissions here as they were used to confirm the enrolment of the user. Let me know if we need to revisit this part.

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/pages/Settings/Settings.js:None
I only updated the hooks permissions. I can had the page too.

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/data/branding.js:226
I assumed these hooks are not mutating settings directly and you need to click 'SAVE' and that is already protected. I am wrong. The logos are updated directly. Will update it.

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/data/returnDays.js:5
This hook is used in the component `Exhcanges.js`. I was unable to find where this component is being used. Let me know if you can find out. @killalau

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/data/returnDays.js:None
Good cleanup @killalau. I feel most of the status changes here don't have any harm as it won't be protected as they are not a function and the mutation function will anyway be protected to not change its status. I had tested manually which made me not remove the protection. I agree that it makes it cleaner so I am removing the `SETTINGS_EDIT` from the statuses.

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/data/returnItemHandlingCostRules.js:None
Good catch!

[HUMAN-LIKELY] shopify-zero-retailer#2751 (PR author: abhinavjainnarvar) | 2025-06-04 | kind=review-comment | app/javascript/retailer-app/data/returnLocations.js:161
True. There are multiple mutations that require admin access. I can update few that seem to be safe. Otherwise, we will keep it as Admin and UI can throw request access popup. The user should still be able to view most of the settings. I am trying to avoid cases where a person might get way more access than expected by retailer and as it affects almost all the retailers, it would be safe to control the backend permission changes. What do you think?

[HUMAN-LIKELY] shopify-zero-retailer#2946 (PR author: abhinavjainnarvar) | 2025-08-12 | kind=review-comment | app/javascript/shop-now/polyfill.js:7
We don't need this polyfill anymore. Added this dynamic import in case we don't have fetch.

[HUMAN-LIKELY] shopify-zero-retailer#2946 (PR author: abhinavjainnarvar) | 2025-08-12 | kind=review-comment | app/javascript/shop-now/utils/dateUtils.js:None
That's a great suggestion.

[HUMAN-LIKELY] shopify-zero-retailer#2946 (PR author: abhinavjainnarvar) | 2025-08-12 | kind=review-body
Added the new package

[HUMAN-LIKELY] denali#1971 (PR author: abhinavjainnarvar) | 2026-05-04 | kind=review-comment | apps/shopify-retailer/src/init.tsx:28
Proper handling will be added in the follow up PRs

[HUMAN-LIKELY] denali#1975 (PR author: abhinavjainnarvar) | 2026-05-05 | kind=review-comment | CODEOWNERS:17
We are planning to add a team for shopify. https://narvar.slack.com/archives/C02A0SY12CX/p1777934172161959
We can discuss more here.

[HUMAN-LIKELY] denali#2083 (PR author: abhinavjainnarvar) | 2026-05-12 | kind=review-comment | apps/shopify-retailer/src/init.tsx:27
Error handling will be added in a follow up PR

[HUMAN-LIKELY] denali#2083 (PR author: abhinavjainnarvar) | 2026-05-12 | kind=review-comment | CODEOWNERS:53
@narvar/octo was renamed to @narvar/shopify-returns. Also, I added the owners where it seem relevant.

[HUMAN-LIKELY] denali#2083 (PR author: abhinavjainnarvar) | 2026-05-13 | kind=review-comment | apps/shopify-retailer/AGENTS.md:1
Yes, it has been intentionally added to help with migration. It will grow as we progress with the migration.

[HUMAN-LIKELY] denali#2083 (PR author: abhinavjainnarvar) | 2026-05-13 | kind=review-comment | apps/shopify-retailer/package.json:15
@niccai Added :)

[HUMAN-LIKELY] denali#2083 (PR author: abhinavjainnarvar) | 2026-05-13 | kind=review-comment | apps/shopify-retailer/src/routes/index.tsx:None
Thanks and noted

[HUMAN-LIKELY] denali#2013 (PR author: abhinavjainnarvar) | 2026-05-21 | kind=review-comment | apps/shopify-retailer/src/auth/shopifyBridge.ts:None
Good suggestion. I looked into it and it seems that the shopify always assumes the JWT is passed in the app and I wanted to keep it optional to allow local development with stubbed JWT. I will try to modify types in order to make that happen.

[HUMAN-LIKELY] denali#2255 (PR author: abhinavjainnarvar) | 2026-05-22 | kind=review-comment | apps/shopify-retailer/src/routes/app/settings/claim-reasons/index.tsx:199
Added only for demo purpose. When the page is properly designed, we will clean this up as well

[HUMAN-LIKELY] denali#2013 (PR author: abhinavjainnarvar) | 2026-05-25 | kind=review-comment | apps/shopify-retailer/src/auth/ShopifyBridgeProvider.tsx:39
Sounds good. Added comments for more clarity

[HUMAN-LIKELY] denali#2293 (PR author: abhinavjainnarvar) | 2026-05-26 | kind=review-comment | apps/shopify-retailer/src/lib/i18n.ts:None
Skipping this one. `i18n.init()` is a config operation (no I/O, no storage probes) — real-world failure modes are effectively none, so the rejection-cache scenario isn't reachable. If init *did* fail at boot, the root error boundary catches it and the app fails to mount; the user refreshes, the module re-evaluates, and `initPromise` is back to `null`. There's no long-lived process accumulating state, so a catch+null-reset would be defensive code for a scenario that can't happen — which the app's CLAUDE.md guidance explicitly says to avoid.

[HUMAN-LIKELY] denali#2293 (PR author: abhinavjainnarvar) | 2026-05-26 | kind=review-comment | apps/shopify-retailer/AGENTS.md:None
Fixed in [c6b58e591](https://github.com/narvar/denali/pull/2293/commits/c6b58e591) — both szero references in AGENTS.md now use absolute `https://github.com/narvar/shopify-zero-retailer/...` URLs on `develop` (szero's default branch).

[HUMAN-LIKELY] denali#2293 (PR author: abhinavjainnarvar) | 2026-05-26 | kind=review-comment | apps/shopify-retailer/src/lib/i18n.ts:76
Good call — added in [19852ee76](https://github.com/narvar/denali/pull/2293/commits/19852ee76). New `src/lib/i18n.test.ts` covers:
- `retailer_i18n` off → only `en` resource bundle loaded
- `retailer_i18n` on → en + pt-BR + zh all loaded
- both `common` and `settings` namespaces register

Uses `vi.resetModules()` between cases so each test gets a fresh i18next singleton (the module-level `initPromise` memo would otherwise carry state across).

[HUMAN-LIKELY] denali#2293 (PR author: abhinavjainnarvar) | 2026-05-26 | kind=review-comment | apps/shopify-retailer/package.json:28
Wording fixed in the PR description — the caret ranges (`^25.1.3` etc) match szero's pins verbatim, so npm resolves the two repos to the same logical version family. "Pinned to szero" was loose phrasing; the description now says "caret ranges matching szero's pins". No code change needed.

[HUMAN-LIKELY] denali#2293 (PR author: abhinavjainnarvar) | 2026-05-27 | kind=review-comment | apps/shopify-retailer/src/lib/i18n.ts:48
This will be added in the future based on the library we end up deciding for managing date and timezones.

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/vite.config.ts:54
Addressed in `e87a3ab65` (rebased form of `5a98a50b7`). The guard now scopes to `command === 'build'` and throws on deploy builds (`mode !== 'production'` → qa20/st20/prod20) while warning on the no-secrets verify build (default `mode === 'production'`), matching your suggested shape. Resolving.

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/MIGRATION.md:204
Fixed in `e87a3ab65` (rebased form of `5a98a50b7`). The doc now reads `VITE_ROLLBAR_ENV` (`qa` / `stg` / `prod`), matching the committed `.env.prod20` value (`prod`). Resolving.

Note: @killalau separately suggested the env *values* themselves (`prod` vs `production`, etc.) should match the Ruby/Rollbar convention — that is tracked in the open `.env.{qa,st,prod}20` threads and left for the author to decide; this thread only covered the doc/value drift you flagged.

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/.env.prod20:2
Flagging for the author: this is a design decision about the Rollbar `environment` naming convention. @niccai aligned these values to `prod`/`stg`/`qa` (admin-app pattern) in `5a98a50b7`; @killalau here suggests matching Ruby (`production`). These two are in tension, so leaving unresolved for @abhinavjainnarvar to decide the canonical convention. Doc and `.env` files are internally consistent at `prod` right now (rebased onto main as of `e87a3ab65`).

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/.env.qa20:2
Flagging for the author — same Rollbar `environment` naming decision as the `.env.prod20` thread (`qa` vs `development`). Leaving unresolved for @abhinavjainnarvar; needs a single canonical convention across all three env files.

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/.env.st20:2
Flagging for the author — same Rollbar `environment` naming decision (`stg` vs `staging`). Leaving unresolved for @abhinavjainnarvar; resolve together with the qa20/prod20 threads under one convention.

[HUMAN-LIKELY] denali#2319 (PR author: abhinavjainnarvar) | 2026-06-17 | kind=review-comment | apps/shopify-retailer/MIGRATION.md:177
Flagging for the author — this is a forward-looking note (revisit Rollbar source-map versioning once CI provides `CIRCLE_SHA1`), already tracked under SHOPZ-5051 per `cded0a38a`. Leaving unresolved for @abhinavjainnarvar to confirm the follow-up is captured and close it out.

[HUMAN-LIKELY] denali#2406 (PR author: abhinavjainnarvar) | 2026-06-22 | kind=pr-comment
Superseeded by 2716

===== SECTION D: AGENT-LIKELY (examples) =====
[AGENT-LIKELY] denali#1975 (PR author: abhinavjainnarvar) | 2026-05-04 | kind=pr-description
## Summary
- Pre-registers `shopify-retailer` in CircleCI parameters and adds a `shopify_retailer_workflow` (npm_install, check-formatting, typecheck, lint, build) so subsequent PRs adding the app dir land with green CI on the integration branch.
- Adds CODEOWNERS entry and `app:shopify-retailer` PR label.
- No `test` job yet — will be added in the test setup PR once vitest is configured.

This is the first PR in the page-by-page Denali migration and targets the long-lived integration branch `feature/denali-shopify-retailer`. The bootstrap PR (#1971) will be rebased onto this once it merges so it can pass CI.

## Test plan
- [x] `node .circleci/validate-ci-config.mjs` passes locally
- [ ] CircleCI green on this PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[AGENT-LIKELY] denali#1999 (PR author: abhinavjainnarvar) | 2026-05-08 | kind=pr-comment
Superseded by the co-resident bundle architecture (SHOPZ-4930-v2). Companion to closing narvar/shopify-zero-retailer#3778.

This PR's `defaultNotFoundComponent: NotFoundRedirect` and `redirectToSzero` utility were the Denali half of the redirect mechanism — they're not needed in the co-resident design. szero's HTML hosts both bundles, a coordinator toggles visibility, no iframe navigation happens.

What carries forward to the new design:
- `apps/shopify-retailer/src/auth/*` (App Bridge hooks) — landing as part of #2013 / SHOPZ-4932, unaffected
- `apps/shopify-retailer/index.html` (App Bridge meta tag + CDN script) — stays; useful for dev-stub fallback today, becomes the bootstrap when Denali goes independent later

What gets discarded:
- `src/utils/szeroNavigation.ts` (the redirect helper)
- `defaultNotFoundComponent` wiring in `init.tsx`
- The `_denali_redirect` marker / loop guard

New work tracked under SHOPZ-4930-v2. Closing without merging.

[AGENT-LIKELY] shopify-zero-retailer#2459 (PR author: killalau) | 2025-03-10 | kind=review-comment | app/graphql/types/return_reason_type.rb:37
This is still throwing error on my local when I update return reasons. Can run below to verify
```
{:error=>#<NoMethodError: undefined method `translator' for #<ReturnReason id: 1, shop_id: 1, reason_code: nil, reason_title: "Incorrect product or size ordered", is_common: true, translated_reason: nil, is_comment_mandatory: true, rules_used_in: [], created_at: "2024-10-09 23:00:47.373724000 +0000", updated_at: "2025-03-10 16:09:50.761192000 +0000", is_valid: true, parent_id: nil, prompt_question: nil, translated_prompt_question: nil, priority: "aj", child_priority: nil, product_tags: [], randomize: false, enable_customer_pictures: false, require_customer_pictures: false, shopify_return_reason: nil, cs_only: false, product_filters: [], min_days_since_fulfilment: nil, min_days_since_creation: nil, min_days_since_delivery: nil, max_days_since_delivery: nil, max_days_since_creation: nil, max_days_since_fulfilment: nil, claim_type: nil, attestation_translation_id: nil>

bin/rspec ./spec/system/retailer/settings_return_reasons_spec.rb:125
```

