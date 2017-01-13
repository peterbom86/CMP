import 'babel-polyfill'

import React from 'react'
import ReactDOM from 'react-dom'

import { createStore, applyMiddleware, combineReducers, compose } from 'redux'
import cmpx from './reducers/cmpx'
import App from './pages/App'
import Products from './components/Products'
import Campaigns from './components/Campaigns'

import { routerMiddleware, syncHistoryWithStore, routerReducer } from 'react-router-redux'
import { Router, Route, hashHistory } from 'react-router'
import thunkMiddleware from 'redux-thunk'
import Menu from './components/Menu'
import { fetchProducts, fetchCampaigns, fetchCustomers } from './actions'

import data from './store/testdata'
import injectTapEventPlugin from 'react-tap-event-plugin'
injectTapEventPlugin()
const helloReducer = combineReducers({ cmpx, routing: routerReducer })
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose
const middleware = routerMiddleware(hashHistory)

let store = createStore(helloReducer, data,
  composeEnhancers(
    applyMiddleware(thunkMiddleware, middleware)
  )
)
const history = syncHistoryWithStore(hashHistory, store)

class Provider extends React.Component {
  getChildContext() {
    return { store: this.props.store }
  }
  render() {
    return this.props.children
  }
}

Provider.childContextTypes = {
  store: React.PropTypes.object
}

ReactDOM.render(
  <Provider store={store}>
    <div>
      <Menu />
      <Router history={history}>
        <Route path="/" component={App} />
        <Route path="/products" component={Products} />
        <Route path="/campaigns" component={Campaigns} />
      </Router>
    </div>
  </Provider>,
  document.getElementById('root')
)

store.dispatch(fetchProducts('a')).then(() =>
  console.log('fetchProducts')
)
store.dispatch(fetchCampaigns('t')).then(() =>
  console.log('fetchCampaigns')
)

store.dispatch(fetchCustomers()).then(() =>
  console.log('fetchCustomers')
) 
