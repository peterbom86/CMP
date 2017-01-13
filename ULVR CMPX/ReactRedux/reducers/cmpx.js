import { productsReducer } from './productReducer'
import campaignReducer from './campaignReducer'
import * as actionTypes from './../actions'

function cmpx(state = {}, action) {
  if (action.type.indexOf('@@') !== -1) {
    return state
  }
  switch (action.type) {
    case actionTypes.REPLACE_STORE:
      return action.data.list
    case actionTypes.RECEIVE_PRODUCTS:
      return { ...state, products: action.products }
    case actionTypes.RECEIVE_CAMPAIGNS:
      return { ...state, campaigns: action.campaigns }
    case actionTypes.RECEIVE_PRODUCT_GROUPS:
      return { ...state, productGroups: action.productGroups }
    case actionTypes.RECEIVE_CUSTOMERS:
      return { ...state, customers: action.customers }
    case actionTypes.ADD_PRODUCT:
      state.products.items = [action.product, ...state.products.items]
      return { ...state }
    case actionTypes.DELETE_PRODUCT:
      state.products.items = [...state.products.items.filter((p) => {
        return p.id !== action.id
      })]
      return { ...state }
    case actionTypes.EDIT_CAMPAIGN:
      return { ...state, selectedCampaign: action.campaign }
    case actionTypes.FILTER_CAMPAIGNS:
      return { ...state, campaigns: action.campaigns }
    case actionTypes.ADD_CAMPAIGN:
      state.campaigns = [action.campaign, ...state.campaigns]
      return { ...state }
    case actionTypes.UPDATE_METADATA:
      state.meta = { ...state.meta, [action.prop]: action.value }
      return { ...state }
    default:
      return {...state,
        products: productsReducer(state.products, action),
        campaign: campaignReducer(state.campaigns, action)
      }
  }
}
export default cmpx
