import React from 'react'
import {
    Accordion,
    AccordionItem,
    AccordionItemHeading,
    AccordionItemButton,
    AccordionItemPanel,
    AccordionItemState
  } from 'react-accessible-accordion'

  import { Icon } from 'semantic-ui-react'

  import './accordion.less'

const BecAccordion = (props) => {
  return(
    <div className='accordionContainer'>
      <div className='accordionContent'>
        <Accordion allowZeroExpanded>
          {props.data.map(faq => (
            <AccordionItem key={faq.question}>
              <AccordionItemHeading className='accordionHeading'>
                <AccordionItemButton className='accordionButton'>
                  <h3>
                    {faq.question}
                  </h3>
                  <AccordionItemState>
                    {({ expanded }) => {
                      return expanded ? (
                        <Icon name='chevron up' />
                      ) : (
                        <Icon name='chevron down' />
                      )
                    }}
                  </AccordionItemState>
                </AccordionItemButton>
              </AccordionItemHeading>
              <AccordionItemPanel>
                <div
                  className='accordionText'
                  dangerouslySetInnerHTML={{ __html: faq.answer }}
                />
              </AccordionItemPanel>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </div>)
}

export default BecAccordion;