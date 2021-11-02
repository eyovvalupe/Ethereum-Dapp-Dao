import { BrowserRouter, Link, Route, Switch } from "react-router-dom";
import { Menu, Row, Col } from "antd";
import { Form, Input, Button, Radio } from 'antd';
import React, { useCallback, useEffect, useState } from "react";
import { Header, AESGCM, RandomNumber, SHA256, SignAndVerify,ECDH } from "./components";
import "antd/dist/antd.css";
import './index.css';
import './App.css';

function App() {

  // Set route variable 
  const [route, setRoute] = useState();
  useEffect(() => {
    setRoute(window.location.pathname);
  }, [setRoute]);

  return (
    <div className="App">
      <Header />
      <BrowserRouter>
        <Menu style={{ justifyContent: "center", textAlign: "center" }} selectedKeys={[route]} mode="horizontal">
          <Menu.Item key="/RandomNumber">
            <Link
              onClick={() => {
                setRoute("/RandomNumber");
              }}
              to="/RandomNumber"
            >
              RandomNumber
            </Link>
          </Menu.Item>
          <Menu.Item key="/AES-GCM">
            <Link
              onClick={() => {
                setRoute("/AES-GCM");
              }}
              to="/AES-GCM"
            >
              AES-GCM
            </Link>
          </Menu.Item>
          <Menu.Item key="/SHA-256">
            <Link
              onClick={() => {
                setRoute("/SHA-256");
              }}
              to="/SHA-256"
            >
              SHA-256
            </Link>
          </Menu.Item>
          <Menu.Item key="/SignAndVeryify">
            <Link
              onClick={() => {
                setRoute("/SignAndVeryify");
              }}
              to="/SignAndVeryify"
            >
              SignAndVeryify
            </Link>
          </Menu.Item>

          <Menu.Item key="/ECDH">
            <Link
              onClick={() => {
                setRoute("/ECDH");
              }}
              to="/ECDH"
            >
              ECDH
            </Link>
          </Menu.Item>

        </Menu>

        <Switch>
          <Route exact path="/RandomNumber">
            <RandomNumber />
          </Route>

          <Route exact path="/AES-GCM">
            <AESGCM />
          </Route>

          {/* IMPORTANT PLACE */}
          <Route exact path="/SHA-256">
            <SHA256 />
          </Route>

          <Route path="/SignAndVeryify">
            <SignAndVerify />
          </Route>

          <Route path="/ECDH">
            <ECDH />
          </Route>
        </Switch>
      </BrowserRouter>
    </div>
  );
}

export default App;
