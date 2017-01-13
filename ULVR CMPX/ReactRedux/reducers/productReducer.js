import { UPDATE_PRODUCT, UPDATE_PRODUCTS_PRODUCT_GROUP, REPLACE_PRODUCT } from './../actions'

export function productsReducer(state = {}, action) {
  return {
    ...state,
    items: state.items.map(p => {
      return productReducer(p, action)
    })
  }
}

export function productReducer(state = {}, action) {
  if (action.id === state.id) {
    switch (action.type) {
      case UPDATE_PRODUCT:
        return { ...state, [action.prop]: action.value }
      case REPLACE_PRODUCT:
        return { ...action.product }
      case UPDATE_PRODUCTS_PRODUCT_GROUP:
        return {
          ...state,
          productGroupId: action.productGroup.id,
          productGroupProductCategoryName: action.productGroup.productCategoryName,
          productGroupName: action.productGroup.name
        }
      default:
        return state
    }
  } else {
    return state
  }
}
