import { LightningElement, api,track,wire } from 'lwc';
import { FlowNavigationFinishEvent, FlowAttributeChangeEvent, FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationPauseEvent } from 'lightning/flowSupport';

export default class LwcToflow extends LightningElement {
@api test="test";
testChange(event){
          this.test = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('test', this.test));
      }

}