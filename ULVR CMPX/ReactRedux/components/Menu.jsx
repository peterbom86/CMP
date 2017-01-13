import React from 'react'
import getMuiTheme from 'material-ui/styles/getMuiTheme'
import AppBar from 'material-ui/AppBar'
import { push } from 'react-router-redux'
import Drawer from 'material-ui/Drawer'
import MenuItem from 'material-ui/MenuItem'
import FontIcon from 'material-ui/FontIcon'
import { connect } from 'react-redux'
import { updateMetadata } from '../actions'
class Menu extends React.Component {
  getChildContext() {
    return { muiTheme: getMuiTheme() }
  }
  toggleAndPush(url, isVisible) {
    this.props.redirect(url); this.props.handleToggle(isVisible)
  }
  render() {
    return (
      <div>
        <AppBar
          title="CMP"
          iconClassNameRight="muidocs-icon-navigation-expand-more"
          onLeftIconButtonTouchTap={() => this.props.handleToggle(true)} />
        <Drawer
          docked={false}
          width={200}
          open={this.props.showLeftMenu}
          onRequestChange={(open) => this.props.handleToggle(false)}
          >
          <MenuItem
            onTouchTap={(e) => { this.toggleAndPush('/', false) } }
            leftIcon={<FontIcon className="material-icons">home</FontIcon>}
            >Hjem</MenuItem>
          <MenuItem onTouchTap={(e) => { this.toggleAndPush('/campaigns', false) } }
            leftIcon={<FontIcon className="material-icons">work</FontIcon>}
            >Kampagner</MenuItem>
          <MenuItem onTouchTap={(e) => { this.toggleAndPush('/products', false) } }
            leftIcon={<FontIcon className="material-icons">local_offer</FontIcon>}
            >Produkter</MenuItem>
        </Drawer>
      </div>
    )
  }
}

Menu.childContextTypes = {
  muiTheme: React.PropTypes.object.isRequired
}

const mapStateToProps = (state) => {
  return {
    showLeftMenu: state.cmpx.meta.showLeftMenu
  }
}
const mapDispatchToProps = (dispatch) => {
  return {
    handleToggle: (value) => {
      dispatch(updateMetadata('showLeftMenu', value))
    },
    redirect: (url) => {
      dispatch(push(url))
    }

  }
}
export default connect(mapStateToProps, mapDispatchToProps)(Menu)
