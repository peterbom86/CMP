export const CHANGE_ITEM_TEXT = 'CHANGE_ITEM_TEXT'
export const RECEIVE_PRODUCTS = 'RECEIVE_PRODUCTS'
export const RECEIVE_CUSTOMERS = 'RECEIVE_CUSTOMERS'
export const RECEIVE_CAMPAIGNS = 'RECEIVE_CAMPAIGNS'
export const UPDATE_METADATA = 'UPDATE_METADATA'

export const FILTER_PRODUCTS = 'FILTER_PRODUCTS'
export const ADD_PRODUCT = 'ADD_PRODUCT'
export const DELETE_PRODUCT = 'DELETE_PRODUCT'

export const UPDATE_PRODUCT = 'UPDATE_PRODUCT'
export const REPLACE_PRODUCT = 'REPLACE_PRODUCT'
export const RECEIVE_PRODUCT_GROUPS = 'EDIT_PRODUCT'
export const EDIT_PRODUCT_PROPERTY = 'EDIT_PRODUCT_PROPERTY'
export const FILTER_CAMPAIGNS = 'FILTER_CAMPAIGNS'
export const ADD_CAMPAIGN = 'ADD_CAMPAIGN'
export const EDIT_CAMPAIGN = 'EDIT_CAMPAIGN'
export const UPDATE_PRODUCTS_PRODUCT_GROUP = 'UPDATE_PRODUCTS_PRODUCT_GROUP'

export function ChangeItemText(text, id) {
  return {
    type: CHANGE_ITEM_TEXT,
    text,
    id
  }
}
export function filterProducts(products) {
  return {
    type: FILTER_PRODUCTS,
    products
  }
}
export function addProduct(product) {
  return {
    type: ADD_PRODUCT,
    product
  }
}
export function deleteProduct(id) {
  return {
    type: DELETE_PRODUCT,
    id
  }
}
export function updateProduct(id, prop, value) {
  return {
    type: UPDATE_PRODUCT,
    id,
    prop,
    value
  }
}
export function updateProductsProductGroup(id, productGroup) {
  return {
    type: UPDATE_PRODUCTS_PRODUCT_GROUP,
    id,
    productGroup
  }
}

export function filterCampaigns(campaigns) {
  return {
    type: FILTER_CAMPAIGNS,
    campaigns
  }
}
export function addCampaign(campaign) {
  return {
    type: ADD_CAMPAIGN,
    campaign
  }
}
export function editCampaign(campaign) {
  return {
    type: EDIT_CAMPAIGN,
    campaign
  }
}

// Thunks
const MAX_ITEMS = 50
const BASE_URL = 'http://localhost:51109/api/'
function receiveProducts(products) {
  return {
    type: RECEIVE_PRODUCTS,
    products
  }
}
function receiveProductGroups(productGroups) {
  return {
    type: RECEIVE_PRODUCT_GROUPS,
    productGroups
  }
}
function receiveCustomers(customers) {
  return {
    type: RECEIVE_CUSTOMERS,
    customers
  }
}
function receiveCampaigns(campaigns) {
  return {
    type: RECEIVE_CAMPAIGNS,
    campaigns
  }
}
export function replaceProduct(product) {
  return {
    type: REPLACE_PRODUCT,
    product,
    id: product.id
  }
}
export function updateMetadata(prop, value) {
  return {
    type: UPDATE_METADATA,
    prop,
    value
  }
}
export function fetchProductGroups(searchString) {
  return dispatch => {
    return fetch(BASE_URL + 'productgroups/search/' + searchString + '/' + MAX_ITEMS)
      .then(response => response.json())
      .then(json => dispatch(receiveProductGroups(json)))
  }
}

export function fetchProducts(searchString, max) {
  return dispatch => {
    return fetch(BASE_URL + 'products/search/' + searchString + '/' + (max || MAX_ITEMS))
      .then(response => response.json())
      .then(json => dispatch(receiveProducts(json)))
  }
}
export function cancelSaveProduct(id) {
  return dispatch => {
    return fetch(BASE_URL + 'products/' + id)
      .then(response => response.json())
      .then(json => dispatch(replaceProduct(json)))
  }
}
export function saveProduct(product) {
  return dispatch => {
    return fetch(BASE_URL + 'products/update/',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(product)
      }
    )
      .then(response => response.json())
      .then(json => dispatch(replaceProduct(json)))
  }
}
export function fetchCampaigns(searchString, max) {
  return dispatch => {
    return fetch(BASE_URL + 'campaigns/search/' + searchString + '/' + (max || MAX_ITEMS))
      .then(response => response.json())
      .then(json => dispatch(receiveCampaigns(json)))
  }
}
export function fetchCustomers() {
  return dispatch => {
    return fetch(BASE_URL + 'customers/')
      .then(response => response.json())
      .then(json => dispatch(receiveCustomers(json)))
  }
}
