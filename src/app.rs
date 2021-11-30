use gloo_console::log;
use yew::{html, Component, Context, Html};

pub enum Msg {
    AddOne,
    SubOne,
}

pub struct Model {
    counter_value: i64,
}

impl Component for Model {
    type Message = Msg;
    type Properties = ();

    fn create(_ctx: &Context<Self>) -> Self {
        Self { counter_value: 0 }
    }

    fn update(&mut self, _ctx: &Context<Self>, msg: Self::Message) -> bool {
        match msg {
            Msg::AddOne => {
                self.counter_value += 1;
                log!("add one");
                true
            }
            Msg::SubOne => {
                self.counter_value -= 1;
                log!("sub one");
                true
            }
        }
    }

    fn view(&self, ctx: &Context<Self>) -> Html {
        html! {
            <div>
                <button onclick={ctx.link().callback(|_| Msg::AddOne)}>{ "+1" }</button>
                <button onclick={ctx.link().callback(|_| Msg::SubOne)}>{ "-1" }</button>
                <p>{ self.counter_value }</p>
            </div>
        }
    }
}
