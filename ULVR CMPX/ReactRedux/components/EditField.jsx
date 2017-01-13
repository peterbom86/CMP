
import React, { PropTypes } from 'react'
import TextField from 'material-ui/TextField'
import AutoComplete from 'material-ui/AutoComplete'

class EditField extends React.Component {
  render() {
    if (this.props.isEditable) {
      switch (this.props.type) {
        case 'combo':
          return (<AutoComplete
            searchText={this.props.value}
            filter={this.props.filter}
            dataSourceConfig={this.props.dataSourceConfig}
            dataSource={this.props.dataSource}
            floatingLabelText={this.props.floatingText}
            onUpdateInput={(e) => { this.props.onSearch(e) } }
            onNewRequest={(selectedObject, index) => { this.props.onChange(selectedObject, index) } }
            value={this.props.value}></AutoComplete>)
        default:
          return (<TextField floatingLabelText={this.props.floatingText} onChange={(e) => { this.props.onChange(e) } } value={this.props.value}></TextField>)
      }
    } else {
      return (
        <span>{this.props.value}</span>
      )
    }
  }
}
EditField.propTypes = {
  value: PropTypes.string.isRequired,
  isEditable: PropTypes.bool.isRequired,
  onChange: PropTypes.function,
  onSearch: PropTypes.function,
  floatingText: PropTypes.string,
  type: PropTypes.string,
  dataSourceConfig: PropTypes.object,
  dataSource: PropTypes.object,
  filter: PropTypes.function
}
EditField.defaultProps = { dataSourceConfig: { text: 'name', value: 'id' }, filter: (f, e) => { return true }, onChange: (e) => { } }
export default EditField
